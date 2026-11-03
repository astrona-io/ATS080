#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

kubectl -n cert-manager scale deployment cert-manager --replicas=1
kubectl -n cert-manager rollout status deployment/cert-manager --timeout=180s

kubectl apply -f - <<'YAML'
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: starfleet-ca
spec:
  selfSigned: {}
YAML
kubectl apply -f - <<'YAML'
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: probe-cert
  namespace: starfleet
spec:
  secretName: probe-tls
  dnsNames:
    - probe.starfleet.svc
    - probe.starfleet.svc.cluster.local
  issuerRef:
    name: starfleet-ca
    kind: ClusterIssuer
YAML
kubectl -n starfleet patch deployment probe --type=json \
  -p '[{"op":"replace","path":"/spec/template/spec/volumes/0/secret/secretName","value":"probe-tls"}]'
kubectl delete clusterrolebinding probe-admin
kubectl -n starfleet wait --for=condition=Ready certificate/probe-cert --timeout=180s
kubectl -n starfleet rollout status deployment/probe --timeout=180s
echo "[solution] Applied."
