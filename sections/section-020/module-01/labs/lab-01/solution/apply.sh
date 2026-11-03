#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$DIR/solution.yaml"
kubectl wait --for=condition=Established crd/databaseclaims.platform.example --timeout=120s
# The API server reloads a changed schema in the background.
sleep 8
echo "[solution] Applied."
