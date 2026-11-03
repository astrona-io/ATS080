#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

kubectl -n starfleet scale deployment scout --replicas=4
kubectl -n starfleet rollout status deployment/scout --timeout=180s

deployment_uid="$(kubectl -n starfleet get deployment scout -o jsonpath='{.metadata.uid}')"
pod_owner_kind="$(kubectl -n starfleet get pods -l app=scout -o jsonpath='{.items[0].metadata.ownerReferences[0].kind}')"
replicaset_name="$(kubectl -n starfleet get pods -l app=scout -o jsonpath='{.items[0].metadata.ownerReferences[0].name}')"
observed_generation="$(kubectl -n starfleet get deployment scout -o jsonpath='{.status.observedGeneration}')"

kubectl -n starfleet create configmap owner-chain \
  --from-literal=deployment-uid="$deployment_uid" \
  --from-literal=replicaset="$replicaset_name" \
  --from-literal=pod-owner-kind="$pod_owner_kind" \
  --from-literal=observed-generation="$observed_generation" \
  --dry-run=client -o yaml | kubectl apply -f -
echo "[solution] Applied."
