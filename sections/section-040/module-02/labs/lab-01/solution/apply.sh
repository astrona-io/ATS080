#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$DIR/solution.yaml"
kubectl -n starfleet wait --for=condition=Ready certificate/scout-cert --timeout=180s
kubectl -n outpost wait --for=condition=Ready certificate/drifter-cert --timeout=180s
echo "[solution] Applied."
