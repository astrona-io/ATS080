#!/usr/bin/env bash
# Starting state for the capstone (ats-080-capstone-040).
# Installs cert-manager, creates the broken integration, then scales the
# cert-manager controller to zero. The learner repairs it.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"


CERT_MANAGER_VERSION="v1.21.3"

# Installs cert-manager from its release manifest and waits until the webhook
# accepts requests. Until the webhook is ready, creating an Issuer fails.
install_cert_manager() {
  echo "Installing cert-manager ${CERT_MANAGER_VERSION}..."
  kubectl apply -f "https://github.com/cert-manager/cert-manager/releases/download/${CERT_MANAGER_VERSION}/cert-manager.yaml"
  for deployment in cert-manager cert-manager-cainjector cert-manager-webhook; do
    kubectl -n cert-manager rollout status "deployment/${deployment}" --timeout=300s
  done
  for crd in certificates issuers clusterissuers certificaterequests; do
    kubectl wait --for=condition=Established "crd/${crd}.cert-manager.io" --timeout=120s
  done
  for _ in $(seq 1 60); do
    if kubectl apply --dry-run=server -f - >/dev/null 2>&1 <<'YAML'
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: readiness-probe
  namespace: default
spec:
  selfSigned: {}
YAML
    then
      return 0
    fi
    sleep 3
  done
  echo "cert-manager webhook did not become ready in time" >&2
  return 1
}

kubectl apply -f "$DIR/manifests/namespaces.yaml"
install_cert_manager
kubectl apply -f "$DIR/manifests/probe.yaml"
sleep 5
kubectl -n cert-manager scale deployment cert-manager --replicas=0
kubectl -n cert-manager rollout status deployment/cert-manager --timeout=120s
echo "[env] Ready: cert-manager ${CERT_MANAGER_VERSION} is installed, the controller is scaled to zero, and the probe integration is broken."
