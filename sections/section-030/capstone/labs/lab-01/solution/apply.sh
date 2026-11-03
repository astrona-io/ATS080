#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$DIR/xrd.yaml"
kubectl wait --for=condition=Established xrd/xdepots.platform.starfleet.example --timeout=120s
kubectl wait --for=condition=Established crd/depots.platform.starfleet.example --timeout=120s
kubectl apply -f "$DIR/composition.yaml"

kubectl apply -f - <<'YAML'
apiVersion: platform.starfleet.example/v1alpha1
kind: Depot
metadata:
  name: scout-depot
  namespace: starfleet
spec:
  replicas: 2
  writeConnectionSecretToRef:
    name: depot-conn
---
apiVersion: platform.starfleet.example/v1alpha1
kind: Depot
metadata:
  name: probe-depot
  namespace: starfleet
spec:
  replicas: 1
YAML

kubectl -n starfleet wait --for=condition=Ready depot/scout-depot --timeout=300s
kubectl -n starfleet wait --for=condition=Ready depot/probe-depot --timeout=300s
kubectl -n starfleet delete depot probe-depot --wait=true --timeout=300s
echo "[solution] Applied."
