#!/usr/bin/env bash
# Audita el ciclo de estado de Terraform de las builds indicadas:
#   ./scripts/audit-state.sh 37 39 45 46 47 48
set -uo pipefail
export PATH="$HOME/.qa-demo-tools/node-v22.23.3-win-x64:$PATH"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ORG="TestQAIML94"
PROJ="LeanTest"
TOKEN=$(tr -d '[:space:]' < "$ROOT/.ado-pat")
AUTH_B64=$(printf ":%s" "$TOKEN" | base64 -w0)
BASE="https://dev.azure.com/$ORG/$PROJ/_apis"

for BUILD in "$@"; do
  echo "═══ build $BUILD ═══"
  CODE=$(curl -s -o "$ROOT/.ado-tmp/audit-tl.json" -w "%{http_code}" -H "Authorization: Basic $AUTH_B64" \
    "$BASE/build/builds/$BUILD/timeline?api-version=7.1")
  if [ "$CODE" != "200" ]; then
    echo "  timeline: HTTP $CODE (no disponible)"
  else
    node -e '
      try {
        const tl=require(process.argv[1]);
        (tl.records||[]).filter(r=>r.type==="Task"&&/terraform destroy|Recuperar estado|Publicar estado/.test(r.name))
          .forEach(r=>console.log("  "+r.name+" → "+r.result));
      } catch(e){ console.log("  timeline no parseable"); }
    ' "$ROOT/.ado-tmp/audit-tl.json"
    LOG=$(node -e '
      try {
        const tl=require(process.argv[1]);
        const r=(tl.records||[]).find(r=>r.name==="terraform destroy"&&r.log);
        console.log(r?r.log.url:"");
      } catch(e){ console.log(""); }
    ' "$ROOT/.ado-tmp/audit-tl.json")
    if [ -n "$LOG" ]; then
      curl -s -H "Authorization: Basic $AUTH_B64" "$LOG" | grep -E "Destroy complete|Resources: [0-9]+|Nada que destruir|Error:" | head -3 | sed 's/^/    /'
    fi
  fi
  ACODE=$(curl -s -o "$ROOT/.ado-tmp/audit-art.json" -w "%{http_code}" -H "Authorization: Basic $AUTH_B64" \
    "$BASE/build/builds/$BUILD/artifacts?api-version=7.1")
  if [ "$ACODE" = "200" ]; then
    node -e '
      const j=require(process.argv[1]);
      console.log("  artefactos: "+((j.value||[]).map(a=>a.name).join(", ")||"ninguno"));
    ' "$ROOT/.ado-tmp/audit-art.json"
  else
    echo "  artefactos: HTTP $ACODE"
  fi
done
