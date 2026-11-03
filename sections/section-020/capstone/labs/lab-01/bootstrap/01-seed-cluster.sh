#!/usr/bin/env bash
# Starting state for the capstone: two namespaces only. starfleet carries the
# label platform.example/prod-allowed=true and outpost has no such label. There
# is no CRD, no Role and no policy. The learner builds the whole API.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
kubectl apply -f "$DIR/manifests/namespaces.yaml"
echo "[lab] Ready."
