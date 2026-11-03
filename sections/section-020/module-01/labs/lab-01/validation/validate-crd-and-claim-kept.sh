#!/usr/bin/env bash
# Check: the CRD was changed in place. probe-db still has the UID that the
# bootstrap recorded, the CRD has the single version v1alpha1 and the scope
# Namespaced.
set -uo pipefail

recorded="$(kubectl -n kube-system get configmap lab-seed -o jsonpath='{.data.probe-db-uid}' 2>/dev/null)"
current="$(kubectl -n starfleet get databaseclaim probe-db -o jsonpath='{.metadata.uid}' 2>/dev/null)"
if [ -z "$current" ]; then
  echo "FAIL: the claim probe-db in starfleet is gone. Deleting the CRD deletes every claim; apply the changed CRD instead"
  exit 1
fi
if [ -z "$recorded" ] || [ "$recorded" != "$current" ]; then
  echo "FAIL: probe-db was deleted and created again"
  exit 1
fi

scope="$(kubectl get crd databaseclaims.platform.example -o jsonpath='{.spec.scope}' 2>/dev/null)"
versions="$(kubectl get crd databaseclaims.platform.example -o jsonpath='{.spec.versions[*].name}' 2>/dev/null)"
if [ "$scope" != "Namespaced" ] || [ "$versions" != "v1alpha1" ]; then
  echo "FAIL: expected scope Namespaced and the single version v1alpha1, found scope '${scope}' and versions '${versions}'"
  exit 1
fi

echo "PASS: the CRD was updated in place and probe-db was kept"
