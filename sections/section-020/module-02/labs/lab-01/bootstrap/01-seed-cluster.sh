#!/usr/bin/env bash
# Starting state for the versions, status and access lab. Environment only: two
# namespaces, the DatabaseClaim CRD with two served versions (v1alpha1 is the
# storage version, nothing is deprecated) and one claim whose spec was changed
# once, so metadata.generation is 2. No Roles and no status.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/namespaces.yaml"
kubectl apply -f "$DIR/manifests/crd.yaml"
kubectl wait --for=condition=Established crd/databaseclaims.platform.example --timeout=120s
sleep 3
kubectl apply -f "$DIR/manifests/scout-db.yaml"
kubectl -n starfleet patch databaseclaim scout-db --type=merge -p '{"spec":{"storageGB":30}}'

uid="$(kubectl -n starfleet get databaseclaim scout-db -o jsonpath='{.metadata.uid}')"
kubectl -n kube-system create configmap lab-seed --from-literal=scout-db-uid="$uid" --dry-run=client -o yaml | kubectl apply -f -
echo "[lab] Ready."
