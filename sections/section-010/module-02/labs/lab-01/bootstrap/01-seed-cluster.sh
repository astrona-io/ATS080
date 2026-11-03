#!/usr/bin/env bash
# Starting state for the blocked-rollout lab. Environment only. The script
# applies healthy workloads and then breaks two Deployments:
#   probe  a rollout to an image tag that does not exist (ImagePullBackOff)
#   scout  a template with a CPU request that no node can satisfy (Unschedulable)
# The old pods of both keep running. It also records the Deployment uids.
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

kubectl -n starfleet set image deployment/probe probe=mccutchen/go-httpbin:2.25.0-does-not-exist
kubectl -n starfleet patch deployment scout -p '{"spec":{"template":{"spec":{"containers":[{"name":"scout","resources":{"requests":{"cpu":"1000"},"limits":{"cpu":"1000"}}}]}}}}'

# Wait until both Deployments report that the progress deadline (60 seconds) passed.
# A timeout is not fatal: the learner can still read the same facts a little later.
kubectl -n starfleet wait --for=condition=Progressing=false deployment/probe --timeout=180s || true
kubectl -n starfleet wait --for=condition=Progressing=false deployment/scout --timeout=180s || true
echo "[lab] Ready."
