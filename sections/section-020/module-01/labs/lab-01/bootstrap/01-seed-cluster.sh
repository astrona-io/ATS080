#!/usr/bin/env bash
# Starting state for the CRD schema lab. Environment only: two namespaces, an
# open DatabaseClaim CRD and one existing claim. The learner tightens the CRD.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"
kubectl wait --for=condition=Established crd/databaseclaims.platform.example --timeout=120s
sleep 3
kubectl apply -f "$DIR/manifests/probe-db.yaml"

# Remember the claim UID, so the grader can tell that the CRD was not deleted
# and recreated (which would delete every claim).
uid="$(kubectl -n starfleet get databaseclaim probe-db -o jsonpath='{.metadata.uid}')"
kubectl -n kube-system create configmap lab-seed --from-literal=probe-db-uid="$uid" --dry-run=client -o yaml | kubectl apply -f -
echo "[lab] Ready."
