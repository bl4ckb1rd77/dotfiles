#!/usr/bin/env bash
set -e

NAMESPACE="dev-datenhaus-index"
CLUSTER_NAME="playground-opensearch-cluster"
OUTPUT_YAML="${CLUSTER_NAME}-transport-cert-custom.yaml"

# Exakt dieselbe Pool-Definition wie im Generierungsskript
POOLS=(
  "masters:3"
  "coordinator:3"
  "data:3"
)

echo "=== Generiere Kubernetes Secret YAML via kubectl dry-run ==="

# Basis-Kommando mit explizitem Secret-Namen und Namespace
CMD_ARGS=(
  kubectl create secret generic "${CLUSTER_NAME}-transport-cert-custom"
  -n "${NAMESPACE}"
  --from-file=ca.crt=./rootCA.crt
)

# Schleife über alle Pools & Replikate
for ITEM in "${POOLS[@]}"; do
  POOL_NAME="${ITEM%%:*}"
  REPLICAS="${ITEM##*:}"

  for (( i=0; i<REPLICAS; i++ )); do
    NODE_NAME="${CLUSTER_NAME}-${POOL_NAME}-${i}"
    
    # Paarweise erst CRT, dann KEY anhängen (Reihenfolge garantiert)
    CMD_ARGS+=(
      "--from-file=${NODE_NAME}.crt=./${NODE_NAME}.crt"
      "--from-file=${NODE_NAME}.key=./${NODE_NAME}.key"
    )
  done
done

# Server-side Dry-Run ausführen und sauber als YAML wegschreiben
"${CMD_ARGS[@]}" --dry-run=server -o yaml > "${OUTPUT_YAML}"

echo "=== Success! YAML generiert: ${OUTPUT_YAML} ==="