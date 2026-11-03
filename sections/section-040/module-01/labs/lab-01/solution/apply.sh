#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$DIR/rbac.yaml"
kubectl apply -f "$DIR/configmap-script.yaml"
kubectl -n beacon-system rollout restart deployment/beacon-operator
kubectl -n beacon-system rollout status deployment/beacon-operator --timeout=180s
# Wait until the operator has reconciled both seeded Beacons.
for name in scout probe; do
  for _ in $(seq 1 60); do
    phase="$(kubectl -n starfleet get beacon "$name" -o jsonpath='{.status.phase}' 2>/dev/null || true)"
    [ "$phase" = "Ready" ] && break
    sleep 2
  done
done
echo "[solution] Applied."
