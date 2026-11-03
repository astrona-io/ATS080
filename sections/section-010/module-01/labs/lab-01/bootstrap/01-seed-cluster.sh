#!/usr/bin/env bash
# Starting state for the reconciliation lab. Environment only: the Starfleet
# workloads, healthy, and a baseline of Deployment uids that the grader uses to
# detect a Deployment that was deleted and created again.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"

for name in scout probe shuttle; do
  kubectl -n starfleet rollout status "deployment/$name" --timeout=240s
done
kubectl -n outpost rollout status deployment/drifter --timeout=180s

kubectl create namespace lab-support --dry-run=client -o yaml | kubectl apply -f -
kubectl -n lab-support create configmap lab-baseline \
  --from-literal=scout-uid="$(kubectl -n starfleet get deployment scout -o jsonpath='{.metadata.uid}')" \
  --from-literal=probe-uid="$(kubectl -n starfleet get deployment probe -o jsonpath='{.metadata.uid}')" \
  --from-literal=shuttle-uid="$(kubectl -n starfleet get deployment shuttle -o jsonpath='{.metadata.uid}')" \
  --from-literal=drifter-uid="$(kubectl -n outpost get deployment drifter -o jsonpath='{.metadata.uid}')" \
  --dry-run=client -o yaml | kubectl apply -f -
echo "[lab] Ready."
