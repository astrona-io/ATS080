#!/usr/bin/env bash
# Environment prep for the Providers, Identities, Connection Secrets And Deletion playground (ats-080-playground-030-02).
# Environment only: no task state is solved. Built with static checks only (untested).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

CROSSPLANE_VERSION="2.4.3"

if ! command -v helm >/dev/null 2>&1; then
  echo "[env] helm 3 or newer is required on this machine." >&2
  exit 1
fi

# Installs Crossplane from its Helm chart and waits for the core pods.
install_crossplane() {
  echo "Installing Crossplane ${CROSSPLANE_VERSION}..."
  helm repo add crossplane-stable https://charts.crossplane.io/stable --force-update >/dev/null
  helm repo update >/dev/null
  helm upgrade --install crossplane crossplane-stable/crossplane \
    --namespace crossplane-system --create-namespace \
    --version "${CROSSPLANE_VERSION}" --wait --timeout 5m
}

# Installs provider-kubernetes and function-patch-and-transform, waits until
# both are healthy, and creates the ProviderConfig that uses the provider's own identity.
install_packages() {
  kubectl apply -f "$DIR/manifests/packages.yaml"
  kubectl wait --for=condition=Healthy provider.pkg.crossplane.io/provider-kubernetes --timeout=300s
  kubectl wait --for=condition=Healthy function.pkg.crossplane.io/function-patch-and-transform --timeout=300s
  kubectl wait --for=condition=Established crd/providerconfigs.kubernetes.crossplane.io --timeout=120s
  kubectl wait --for=condition=Established crd/objects.kubernetes.crossplane.io --timeout=120s
  kubectl apply -f "$DIR/manifests/providerconfig.yaml"
}

install_crossplane
install_packages
kubectl apply -f "$DIR/manifests/namespaces.yaml"
kubectl apply -f "$DIR/manifests/rbac-limited.yaml"
kubectl apply -f "$DIR/manifests/xrd-outpost.yaml"
kubectl wait --for=condition=Established xrd/xoutposts.platform.starfleet.example --timeout=120s
kubectl wait --for=condition=Established crd/outposts.platform.starfleet.example --timeout=120s
kubectl apply -f "$DIR/manifests/composition.yaml"
kubectl apply -f "$DIR/manifests/claims.yaml"
echo "[env] Ready."
