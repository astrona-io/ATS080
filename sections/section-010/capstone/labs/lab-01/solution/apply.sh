#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

kubectl -n starfleet set image deployment/scout scout=ghcr.io/stefanprodan/podinfo:6.15.0
kubectl -n starfleet patch deployment probe --type=json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/path","value":"/get"}]'
for name in scout probe; do
  kubectl -n starfleet rollout status "deployment/${name}" --timeout=180s
done

kubectl -n starfleet patch configmap decommissioned-beacon --type=merge -p '{"metadata":{"finalizers":null}}'

scout_uid="$(kubectl -n starfleet get deployment scout -o jsonpath='{.metadata.uid}')"
revision="$(kubectl -n starfleet get deployment scout -o jsonpath='{.metadata.annotations.deployment\.kubernetes\.io/revision}')"
kubectl apply -f - <<YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: release-note
  namespace: starfleet
  ownerReferences:
    - apiVersion: apps/v1
      kind: Deployment
      name: scout
      uid: ${scout_uid}
data:
  revision: "${revision}"
  image: ghcr.io/stefanprodan/podinfo:6.15.0
YAML
echo "[solution] Applied."
