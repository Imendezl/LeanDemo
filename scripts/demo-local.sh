#!/usr/bin/env bash
# DEMO COMPLETA EN LOCAL (sin Azure): recorre el mismo ciclo de vida que el pipeline
# de Azure DevOps, pero contra localhost.
#
#   1. Instala dependencias            (npm install en frontend, backend y tests)
#   2. Pruebas unitarias               (Vitest: validación del formulario)
#   3. Compila el frontend             (vite build)
#   4. "Aprovisiona" y arranca la app  (backend Express en :3000 sirviendo el frontend)
#   5. Ejecuta la suite BDD            (Gherkin + Playwright: UI + API) → informe HTML + JUnit
#   6. Limpieza SIEMPRE                (para el servidor, aunque fallen las pruebas)
#
# Uso:  ./scripts/demo-local.sh [--headed | --ui] [argumentos extra de playwright…]
#
#   --headed   ejecuta la suite BDD con el navegador visible (equivalente a Cypress open)
#   --ui       abre el modo UI interactivo de Playwright (timeline, inspector, watch)
#
# Ejemplos:
#   ./scripts/demo-local.sh
#   ./scripts/demo-local.sh --headed
#   ./scripts/demo-local.sh --headed features/ui/user-registration.feature
set -euo pipefail

# Si se invocó con el bash interno (usr\bin\bash.exe) el PATH puede venir sin las
# herramientas estándar de Git Bash: las anteponemos.
case ":$PATH:" in
  *":/usr/bin:"*) ;;
  *) export PATH="/usr/bin:/bin:$PATH" ;;
esac

# Node.js: si no está en el PATH, busca el Node portable de la demo (~/.qa-demo-tools).
if ! command -v node >/dev/null 2>&1; then
  for dir in "$HOME"/.qa-demo-tools/node-v2*; do
    if [ -x "$dir/node.exe" ]; then
      export PATH="$dir:$PATH"
      echo "Usando Node portable: $dir"
      break
    fi
  done
fi
command -v node >/dev/null 2>&1 || {
  echo "✘ Node.js no encontrado. Instala Node 20+ o colócalo en ~/.qa-demo-tools/node-vXX-win-x64." >&2
  exit 1
}

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_URL="http://localhost:3000"
SERVER_PID=""

# Flags propios; cualquier otro argumento se delega a `playwright test`
# (p. ej. un .feature concreto o --grep@tag).
HEADED=0
UI=0
EXTRA=()
while [ $# -gt 0 ]; do
  case "$1" in
    --headed) HEADED=1 ;;
    --ui)     UI=1 ;;
    *)        EXTRA+=("$1") ;;
  esac
  shift
done

# ── Limpieza garantizada (equivalente a condition: always() en el pipeline) ──
cleanup() {
  if [ -n "$SERVER_PID" ]; then
    echo ""
    echo "▶ 6/6 · Limpieza: deteniendo la aplicación (PID $SERVER_PID)…"
    kill "$SERVER_PID" 2>/dev/null || true
    # Refuerzo en Windows por si MSYS no termina el proceso hijo
    taskkill.exe //F //PID "$SERVER_PID" >/dev/null 2>&1 || true
  fi
  echo "✔ Ciclo completo. Informe: tests/reports/html/index.html"
}
trap cleanup EXIT

step() { echo ""; echo "━━━ $1 ━━━"; }

# 1 · Dependencias
step "1/6 · Instalando dependencias"
(cd "$ROOT/app/backend"  && [ -d node_modules ] || npm install --no-audit --no-fund)
(cd "$ROOT/app/frontend" && [ -d node_modules ] || npm install --no-audit --no-fund)
(cd "$ROOT/tests"        && [ -d node_modules ] || npm install --no-audit --no-fund)

# 2 · Unitarias
step "2/6 · Pruebas unitarias (Vitest)"
(cd "$ROOT/app/frontend" && npm test)

# 3 · Build del frontend
step "3/6 · Compilando frontend (vite build)"
(cd "$ROOT/app/frontend" && npm run build)

# 4 · Arranque de la app (backend sirve el frontend compilado)
step "4/6 · Arrancando aplicación en $BASE_URL"
if curl -sf "$BASE_URL/api/health" >/dev/null 2>&1; then
  echo "⚠ Ya hay una aplicación sana en :3000; se reutiliza (no se lanzará limpieza de proceso)."
else
  cd "$ROOT/app/backend"
  PORT=3000 APP_ENV=qa-local node src/server.js &> "$ROOT/.app.log" &
  SERVER_PID=$!
  cd "$ROOT"
  for _ in $(seq 1 20); do
    curl -sf "$BASE_URL/api/health" >/dev/null 2>&1 && break
    sleep 1
  done
  curl -sf "$BASE_URL/api/health" >/dev/null 2>&1 || { echo "✘ La app no arrancó. Log:" >&2; cat "$ROOT/.app.log" >&2; exit 1; }
  curl -s -X POST "$BASE_URL/api/__test__/reset" >/dev/null || true
  echo "App lista (PID $SERVER_PID)."
fi

# 5 · Suite BDD
if [ "$UI" = "1" ]; then
  step "5/6 · Suite BDD en modo UI interactivo (cierra la ventana para terminar)"
  (cd "$ROOT/tests" && export BASE_URL="$BASE_URL" && npx bddgen && npx playwright test --ui ${EXTRA+"${EXTRA[@]}"})
elif [ "$HEADED" = "1" ]; then
  step "5/6 · Suite BDD con navegador visible (Gherkin ES + Playwright)"
  (cd "$ROOT/tests" && BASE_URL="$BASE_URL" npm run test:headed -- ${EXTRA+"${EXTRA[@]}"})
else
  step "5/6 · Ejecutando suite BDD (Gherkin ES + Playwright)"
  (cd "$ROOT/tests" && BASE_URL="$BASE_URL" npm test -- ${EXTRA+"${EXTRA[@]}"})
fi

echo ""
echo "✘/✔ Resumen: revisa el informe HTML con:  cd tests && npx playwright show-report reports/html"
