#!/usr/bin/env bash
# 3/4 · EJECUTAR PRUEBAS: lanza la suite BDD (Gherkin + Playwright) contra el entorno indicado.
#
#   ./scripts/run-tests.sh [terraform-outputs.json]
#   BASE_URL=http://localhost:3000 ./scripts/run-tests.sh   # contra la app local
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/helpers.sh"

if [ -z "${BASE_URL:-}" ]; then
  OUT_FILE="${1:-$ROOT/infra/terraform-outputs.json}"
  BASE_URL="$(tf_output "$OUT_FILE" webapp_url)"
fi
export BASE_URL

echo "▶ Ejecutando suite BDD contra $BASE_URL"
cd "$ROOT/tests"

if [ ! -d node_modules ]; then
  echo "▶ Instalando dependencias de la suite…"
  npm install --no-audit --no-fund
fi

npm test

echo ""
echo "✔ Pruebas terminadas. Informe HTML: tests/reports/html/index.html"
echo "  Ábrelo con: cd tests && npx playwright show-report reports/html"
