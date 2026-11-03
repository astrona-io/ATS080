#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$DIR/composition.yaml"
kubectl apply -f - <<'YAML'
apiVersion: platform.starfleet.example/v1alpha1
kind: Outpost
metadata:
  name: scout
  namespace: starfleet
spec:
  replicas: 2
YAML

kubectl -n starfleet wait --for=condition=Ready outpost/scout --timeout=300s
echo "[solution] Applied."
