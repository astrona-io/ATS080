#!/usr/bin/env bash
# Check: the whole cert-manager operator runs, its CRDs exist and the controller holds the lease.
set -uo pipefail
fail=0

for deployment in cert-manager cert-manager-cainjector cert-manager-webhook; do
  replicas="$(kubectl -n cert-manager get deployment "$deployment" -o jsonpath='{.spec.replicas}' 2>/dev/null)"
  available="$(kubectl -n cert-manager get deployment "$deployment" -o jsonpath='{.status.availableReplicas}' 2>/dev/null)"
  if [ "$replicas" != "1" ] || [ "${available:-0}" != "1" ]; then
    echo "FAIL: Deployment $deployment must run 1 available replica (spec ${replicas:-none}, available ${available:-0})"
    fail=1
  fi
done
crds="$(kubectl get crd -o name 2>/dev/null | grep -c '\.cert-manager\.io$')"
if [ "$crds" != "6" ]; then
  echo "FAIL: expected 6 cert-manager CRDs, found $crds"
  fail=1
fi
holder="$(kubectl -n kube-system get lease cert-manager-controller -o jsonpath='{.spec.holderIdentity}' 2>/dev/null)"
if [ -z "$holder" ]; then
  echo "FAIL: no controller holds the lease cert-manager-controller in kube-system"
  fail=1
fi
if [ "$fail" -eq 0 ]; then
  echo "PASS: cert-manager runs and the controller is the leader"
fi
exit "$fail"
