#!/usr/bin/env bash
# Starting state for the Complete The Beacon Operator lab (ats-080-lab-040-01).
# Installs the CRD and a starter operator that only creates the child ConfigMap.
# No ownerReference, no status, no finalizer: the learner adds them.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/namespaces.yaml"
kubectl apply -f "$DIR/manifests/crd-beacon.yaml"
kubectl wait --for=condition=Established crd/beacons.ops.starfleet.example --timeout=120s
kubectl apply -f "$DIR/manifests/rbac-starter.yaml"
kubectl apply -f "$DIR/manifests/operator-starter.yaml"
kubectl -n beacon-system rollout status deployment/beacon-operator --timeout=180s
kubectl apply -f "$DIR/manifests/beacons.yaml"
for name in scout probe; do
  for _ in $(seq 1 30); do
    if kubectl -n starfleet get configmap "beacon-$name" >/dev/null 2>&1; then
      break
    fi
    sleep 2
  done
done
echo "[env] Ready: CRD, starter operator and Beacons scout and probe exist."
