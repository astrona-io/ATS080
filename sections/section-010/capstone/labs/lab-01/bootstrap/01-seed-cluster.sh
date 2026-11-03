#!/usr/bin/env bash
# Starting state for the capstone. Environment only. The script applies healthy
# workloads and then breaks them:
#   scout   a rollout to an image tag that does not exist (ImagePullBackOff)
#   probe   a readiness probe path that returns 404 (pods run but never ready)
#   decommissioned-beacon  a ConfigMap whose deletion is held by a finalizer
# The old pods of both Deployments keep running. It also records the uids.
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

kubectl -n starfleet set image deployment/scout scout=ghcr.io/stefanprodan/podinfo:6.15.0-does-not-exist
kubectl -n starfleet patch deployment probe --type=json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/path","value":"/ready"}]'

# A ConfigMap that is being deleted but is held by a finalizer. No controller
# owns this finalizer, so the learner has to release it.
kubectl apply -f - <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: decommissioned-beacon
  namespace: starfleet
  finalizers:
    - starfleet.example.com/cleanup
data:
  site: outpost
YAML
kubectl -n starfleet create configmap active-beacon --from-literal=site=starfleet --dry-run=client -o yaml | kubectl apply -f -
kubectl -n starfleet delete configmap decommissioned-beacon --wait=false

# Wait until both Deployments report that the progress deadline (60 seconds) passed.
# A timeout is not fatal: the learner can still read the same facts a little later.
kubectl -n starfleet wait --for=condition=Progressing=false deployment/scout --timeout=180s || true
kubectl -n starfleet wait --for=condition=Progressing=false deployment/probe --timeout=180s || true
echo "[lab] Ready."
