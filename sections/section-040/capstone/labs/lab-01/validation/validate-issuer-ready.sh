#!/usr/bin/env bash
# Check: a selfSigned ClusterIssuer named starfleet-ca exists and is Ready.
set -uo pipefail
fail=0

for _ in $(seq 1 30); do
  ready="$(kubectl get clusterissuer starfleet-ca -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)"
  [ "$ready" = "True" ] && break
  sleep 3
done
if ! kubectl get clusterissuer starfleet-ca >/dev/null 2>&1; then
  echo "FAIL: ClusterIssuer starfleet-ca does not exist"
  exit 1
fi
if [ "$ready" != "True" ]; then
  echo "FAIL: ClusterIssuer starfleet-ca is not Ready (Ready is '${ready:-empty}')"
  fail=1
fi
selfsigned="$(kubectl get clusterissuer starfleet-ca -o jsonpath='{.spec.selfSigned}' 2>/dev/null)"
if [ -z "$selfsigned" ]; then
  echo "FAIL: ClusterIssuer starfleet-ca is not of type selfSigned"
  fail=1
fi
if [ "$fail" -eq 0 ]; then
  echo "PASS: ClusterIssuer starfleet-ca is Ready"
fi
exit "$fail"
