#!/usr/bin/env bash
# Check: the probe service account no longer has cluster-admin.
set -uo pipefail
fail=0

bindings="$(kubectl get clusterrolebindings -o json 2>/dev/null | jq -r '
  .items[]
  | select(.roleRef.name == "cluster-admin")
  | select(any(.subjects[]?; .kind == "ServiceAccount" and .name == "probe" and .namespace == "starfleet"))
  | .metadata.name')"
if [ -n "$bindings" ]; then
  echo "FAIL: the service account probe is still bound to cluster-admin by: $bindings"
  fail=1
fi
got="$(kubectl auth can-i get secrets --all-namespaces --as=system:serviceaccount:starfleet:probe 2>/dev/null)"
if [ "$got" != "no" ]; then
  echo "FAIL: the service account probe can still read Secrets in every namespace"
  fail=1
fi
if ! kubectl -n starfleet get serviceaccount probe >/dev/null 2>&1; then
  echo "FAIL: the service account probe must still exist"
  fail=1
fi
if [ "$fail" -eq 0 ]; then
  echo "PASS: probe has no cluster-admin access"
fi
exit "$fail"
