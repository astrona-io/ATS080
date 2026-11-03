#!/usr/bin/env bash
# Check: the provider service account can create Deployments, and it is not
# bound to cluster-admin (directly or through a group-wide binding to its name).
set -uo pipefail

SA="system:serviceaccount:crossplane-system:provider-kubernetes"
if [ "$(kubectl auth can-i create deployments.apps --as="$SA" 2>/dev/null)" != "yes" ]; then
  echo "FAIL: the provider service account cannot create Deployments yet"
  exit 1
fi
admin="$(kubectl get clusterrolebinding -o json | jq -r '
  .items[] | select(.roleRef.name == "cluster-admin")
  | select([.subjects[]? | select(.kind == "ServiceAccount" and .name == "provider-kubernetes" and .namespace == "crossplane-system")] | length > 0)
  | .metadata.name')"
if [ -n "$admin" ]; then
  echo "FAIL: the provider service account is bound to cluster-admin through: $admin"
  exit 1
fi
if [ "$(kubectl auth can-i delete nodes --as="$SA" 2>/dev/null)" = "yes" ]; then
  echo "FAIL: the provider service account can delete nodes, so its access is too wide"
  exit 1
fi
echo "PASS: the provider can manage Deployments without cluster-admin"
