#!/usr/bin/env bash
# 2/4 · CONFIGURAR Y DESPLEGAR: compila el frontend, empaqueta backend+frontend
# y lo despliega en la Web App del entorno efímero.
#
#   ./scripts/deploy.sh [terraform-outputs.json]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/helpers.sh"

OUT_FILE="${1:-$ROOT/infra/terraform-outputs.json}"
RESOURCE_GROUP="$(tf_output "$OUT_FILE" resource_group_name)"
WEBAPP_NAME="$(tf_output "$OUT_FILE" webapp_name)"
WEBAPP_URL="$(tf_output "$OUT_FILE" webapp_url)"

echo "▶ Compilando frontend…"
(cd "$ROOT/app/frontend" && npm run build)

echo "▶ Empaquetando aplicación (backend + frontend compilado)…"
STAGING="$ROOT/.deploy-pkg"
rm -rf "$STAGING" "$ROOT/app.zip"
mkdir -p "$STAGING/public"
cp "$ROOT/app/backend/package.json" "$STAGING/"
cp -r "$ROOT/app/backend/src" "$STAGING/src"
cp -r "$ROOT/app/frontend/dist/." "$STAGING/public/"

cd "$STAGING"
if command -v zip >/dev/null 2>&1; then
  zip -qr "$ROOT/app.zip" .
elif [ -x /c/Windows/System32/tar.exe ]; then
  # bsdtar de Windows crea zip con la opción -a según la extensión
  /c/Windows/System32/tar.exe -a -cf "$ROOT/app.zip" .
else
  echo "No se encontró 'zip' ni bsdtar para empaquetar." >&2
  exit 1
fi
cd "$ROOT"

echo "▶ Desplegando en '$WEBAPP_NAME' (grupo '$RESOURCE_GROUP')…"
az webapp deploy \
  --resource-group "$RESOURCE_GROUP" \
  --name "$WEBAPP_NAME" \
  --src-path "$ROOT/app.zip" \
  --type zip

echo "▶ Esperando a que la aplicación esté sana…"
esperar_salud "$WEBAPP_URL" 40

echo ""
echo "✔ Despliegue completado. Smoke test de salud:"
curl -sf "${WEBAPP_URL%/}/api/health"
echo ""
