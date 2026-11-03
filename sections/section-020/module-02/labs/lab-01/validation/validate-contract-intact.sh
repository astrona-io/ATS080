#!/usr/bin/env bash
# Check: scout-db has the UID that the bootstrap recorded (the CRD was not
# deleted and recreated), and a dry-run create with an unknown engine is
# rejected through both versions (the schema was not weakened).
set -uo pipefail

recorded="$(kubectl -n kube-system get configmap lab-seed -o jsonpath='{.data.scout-db-uid}' 2>/dev/null)"
current="$(kubectl -n starfleet get databaseclaim scout-db -o jsonpath='{.metadata.uid}' 2>/dev/null)"
if [ -z "$current" ]; then
  echo "FAIL: the claim scout-db is gone. Deleting the CRD deletes every claim"
  exit 1
fi
if [ -z "$recorded" ] || [ "$recorded" != "$current" ]; then
  echo "FAIL: scout-db was deleted and created again"
  exit 1
fi

for version in v1alpha1 v1beta1; do
  claim="apiVersion: platform.example/${version}
kind: DatabaseClaim
metadata:
  name: grader-oracle
  namespace: starfleet
spec:
  engine: oracle"
  if printf '%s\n' "$claim" | kubectl create --dry-run=server -f - >/dev/null 2>&1; then
    echo "FAIL: ${version} accepted engine oracle, so the schema was weakened"
    exit 1
  fi
done

echo "PASS: scout-db was kept and both versions still reject an unknown engine"
