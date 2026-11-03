#!/usr/bin/env bash
# Check: only namespaced Issuers were used and cert-manager was left alone.
set -uo pipefail
fail=0

count="$(kubectl get clusterissuers -o name 2>/dev/null | wc -l | tr -d ' ')"
if [ "$count" != "0" ]; then
  echo "FAIL: $count ClusterIssuer resources exist. The task asks for namespaced Issuers only"
  fail=1
fi
for deployment in cert-manager cert-manager-cainjector cert-manager-webhook; do
  replicas="$(kubectl -n cert-manager get deployment "$deployment" -o jsonpath='{.spec.replicas}' 2>/dev/null)"
  available="$(kubectl -n cert-manager get deployment "$deployment" -o jsonpath='{.status.availableReplicas}' 2>/dev/null)"
  if [ "$replicas" != "1" ] || [ "${available:-0}" != "1" ]; then
    echo "FAIL: Deployment $deployment in cert-manager must run 1 replica (spec $replicas, available ${available:-0})"
    fail=1
  fi
done
image="$(kubectl -n cert-manager get deployment cert-manager -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)"
if [ "$image" != "quay.io/jetstack/cert-manager-controller:v1.21.3" ]; then
  echo "FAIL: the cert-manager controller image changed to $image"
  fail=1
fi
if [ "$fail" -eq 0 ]; then
  echo "PASS: only namespaced Issuers, cert-manager unchanged"
fi
exit "$fail"
