#!/usr/bin/env bash
# 4/4 · LIMPIAR: destruye el entorno efímero para no incurrir en costes.
#
#   ./scripts/cleanup.sh qa-pr-42
#
# En el pipeline esta etapa se ejecuta SIEMPRE (condition: always()),
# incluso si las pruebas fallan: ningún entorno debe sobrevivir a su ejecución.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_NAME="${1:?Uso: cleanup.sh <nombre-entorno> (el mismo usado en provision.sh)}"

echo "▶ Destruyendo entorno efímero '$ENV_NAME'…"
cd "$ROOT/infra"

terraform init -input=false
terraform destroy -auto-approve -input=false -var "environment_name=$ENV_NAME"

rm -f "$ROOT/infra/terraform-outputs.json" "$ROOT/app.zip"

echo "✔ Entorno '$ENV_NAME' eliminado. Coste residual: 0 €."
