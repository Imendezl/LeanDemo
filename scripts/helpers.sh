#!/usr/bin/env bash
# Helpers compartidos por los scripts del ciclo de vida de QA.

# tf_output <fichero-outputs.json> <clave> → imprime el valor de una salida de Terraform
tf_output() {
  local file="$1" key="$2"
  [ -f "$file" ] || { echo "No existe $file: ejecuta primero provision.sh" >&2; return 1; }
  node -e '
    const outputs = require(process.argv[1]);
    const value = outputs[process.argv[2]];
    if (!value) { console.error(`La salida "${process.argv[2]}" no existe en ${process.argv[1]}`); process.exit(1); }
    console.log(value.value);
  ' "$file" "$key"
}

# esperar_salud <base-url> [intentos] → hace polling de /api/health
esperar_salud() {
  local base_url="$1" intentos="${2:-30}"
  for _ in $(seq 1 "$intentos"); do
    if curl -sf "${base_url%/}/api/health" >/dev/null 2>&1; then
      return 0
    fi
    sleep 3
  done
  echo "La aplicación no respondió en ${base_url} tras $((intentos * 3))s" >&2
  return 1
}
