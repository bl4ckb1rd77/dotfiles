#!/usr/bin/env bash

# Zielordner erstellen
SCHEMA_DIR="$HOME/.config/nvim/schemas/crds"
mkdir -p "$SCHEMA_DIR"

echo "Lese CRDs lokal via kubectl..."

# Verarbeitet die CRDs komplett lokal im Speicher
kubectl get crd -o json | jq -c '.items[]' | while read -r crd; do
  name=$(echo "$crd" | jq -r '.metadata.name')
  echo "$crd" | jq '.spec.versions[-1].schema.openAPIV3Schema' > "$SCHEMA_DIR/${name}.json"
  echo " -> Extrahiert: ${name}.json"
done

echo "Fertig! Alle Cluster-CRDs liegen lokal."
