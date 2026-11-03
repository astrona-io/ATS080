#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

kubectl patch crd databaseclaims.platform.example --type=json -p '[
  {"op": "replace", "path": "/spec/versions/0/storage", "value": false},
  {"op": "replace", "path": "/spec/versions/1/storage", "value": true},
  {"op": "add", "path": "/spec/versions/0/deprecated", "value": true},
  {"op": "add", "path": "/spec/versions/0/deprecationWarning", "value": "platform.example/v1alpha1 DatabaseClaim is deprecated; use platform.example/v1beta1"}
]'

kubectl apply -f - <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: database-claim-editor
  namespace: starfleet
rules:
  - apiGroups: ["platform.example"]
    resources: ["databaseclaims"]
    verbs: ["create", "get", "list", "watch", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: database-claim-editor
  namespace: starfleet
subjects:
  - kind: Group
    name: team-starfleet
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: database-claim-editor
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: database-claim-viewer
  namespace: starfleet
rules:
  - apiGroups: ["platform.example"]
    resources: ["databaseclaims"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: database-claim-viewer
  namespace: starfleet
subjects:
  - kind: Group
    name: auditors
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: database-claim-viewer
  apiGroup: rbac.authorization.k8s.io
YAML

generation="$(kubectl -n starfleet get databaseclaim scout-db -o jsonpath='{.metadata.generation}')"
now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
kubectl -n starfleet patch databaseclaim scout-db --subresource=status --type=merge -p "{\"status\":{\"phase\":\"Ready\",\"observedGeneration\":${generation},\"conditions\":[{\"type\":\"Ready\",\"status\":\"True\",\"reason\":\"Provisioned\",\"message\":\"The database accepts connections.\",\"observedGeneration\":${generation},\"lastTransitionTime\":\"${now}\"}]}}"
echo "[solution] Applied."
