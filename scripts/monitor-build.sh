#!/usr/bin/env bash
# Monitoriza la build indicada (por defecto la 24) hasta que termina,
# imprimiendo las transiciones de estado de sus etapas.
set -uo pipefail

export PATH="$HOME/.qa-demo-tools/node-v22.23.3-win-x64:$PATH"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ORG="TestQAIML94"
PROJ="LeanTest"
BUILD="${1:-24}"
TOKEN=$(tr -d '[:space:]' < "$ROOT/.ado-pat")
AUTH_B64=$(printf ":%s" "$TOKEN" | base64 -w0)
BASE="https://dev.azure.com/$ORG/$PROJ/_apis/build/builds/$BUILD"

LAST_SIG=""
for i in $(seq 1 100); do
  SNAPSHOT=$(curl -s -H "Authorization: Basic $AUTH_B64" "$BASE/timeline?api-version=7.1" | node -e '
    let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{
      try {
        const j=JSON.parse(d);
        const stages=(j.records||[]).filter(r=>r.type==="Stage")
          .map(r=>`${r.name}:${r.state==="completed"?(r.result||"completed"):r.state}`).join(" ");
        console.log(stages);
      } catch { console.log("(sin timeline)"); }
    })')
  STATE=$(curl -s -H "Authorization: Basic $AUTH_B64" "$BASE?api-version=7.1" | node -e '
    let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{
      try { const j=JSON.parse(d); console.log(j.status+":"+ (j.result||"-")); } catch { console.log("?"); }
    })')
  SIG="$STATE|$SNAPSHOT"
  if [ "$SIG" != "$LAST_SIG" ]; then
    echo "[$(date +%H:%M:%S)] build=$STATE | $SNAPSHOT"
    LAST_SIG="$SIG"
  fi
  case "$STATE" in
    completed:*) break ;;
  esac
  sleep 20
done

echo ""
RESULT=$(echo "$STATE" | cut -d: -f2)
echo "RESULTADO FINAL: $RESULT"
echo "URL: https://dev.azure.com/$ORG/$PROJ/_build/results?buildId=$BUILD"
