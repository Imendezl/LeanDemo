#!/usr/bin/env bash
# 1/4 · APROVISIONAR: crea un entorno efímero de QA en Azure con Terraform.
#
#   ./scripts/provision.sh qa-pr-42
#
# Cada nombre de entorno genera recursos únicos (rg/app/st/appi + sufijo aleatorio),
# por lo que se pueden tener N entornos en paralelo sin colisiones.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_NAME="${1:?Uso: provision.sh <nombre-entorno> (p. ej. qa-pr-42)}"

echo "▶ Aprovisionando entorno efímero '$ENV_NAME' con Terraform…"
cd "$ROOT/infra"

terraform init -input=false
terraform apply -auto-approve -input=false -var "environment_name=$ENV_NAME"

terraform output -json > "$ROOT/infra/terraform-outputs.json"

echo ""
echo "✔ Entorno '$ENV_NAME' listo:"
node -e '
  const outputs = require(process.argv[1]);
  for (const key of ["resource_group_name", "webapp_url", "reports_url"]) {
    console.log(`   ${key.padEnd(22)} ${outputs[key].value}`);
  }
' "$ROOT/infra/terraform-outputs.json"
