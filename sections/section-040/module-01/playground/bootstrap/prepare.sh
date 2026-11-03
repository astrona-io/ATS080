#!/usr/bin/env bash
# Environment prep for the operator pattern playground (ats-080-playground-040-01).
# Environment only: no CRD, no operator, no task state.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/namespaces.yaml"
for namespace in starfleet beacon-system beacon-registry; do
  kubectl wait --for=jsonpath='{.status.phase}'=Active "namespace/$namespace" --timeout=60s
done
echo "[env] Ready: namespaces starfleet, beacon-system and beacon-registry exist. No CRD and no operator yet."
