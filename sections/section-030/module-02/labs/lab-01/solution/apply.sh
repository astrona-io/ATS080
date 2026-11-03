#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Least-privilege access for the provider to Deployments.
kubectl apply -f - <<'YAML'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: provider-kubernetes-deployments
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: provider-kubernetes-deployments
subjects:
  - kind: ServiceAccount
    name: provider-kubernetes
    namespace: crossplane-system
roleRef:
  kind: ClusterRole
  name: provider-kubernetes-deployments
  apiGroup: rbac.authorization.k8s.io
YAML

# 2. Connection secret for scout.
kubectl -n starfleet patch outpost scout --type=merge -p '{"spec":{"writeConnectionSecretToRef":{"name":"scout-conn"}}}'

# 3. Orphan the record ConfigMap when a claim is deleted.
kubectl apply -f "$DIR/composition.yaml"

kubectl -n starfleet wait --for=condition=Ready outpost/scout --timeout=300s
kubectl -n starfleet wait --for=condition=Ready outpost/probe --timeout=300s

# Wait until the Objects of probe carry deletionPolicy Orphan for the record.
for _ in $(seq 1 90); do
  count="$(kubectl get objects.kubernetes.crossplane.io -l crossplane.io/claim-name=probe -o json | jq '[.items[] | select(.spec.deletionPolicy == "Orphan")] | length')"
  if [ "$count" -ge 1 ]; then
    break
  fi
  sleep 4
done

kubectl -n starfleet delete outpost probe --wait=true --timeout=300s
echo "[solution] Applied."
