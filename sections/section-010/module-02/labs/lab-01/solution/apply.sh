#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

kubectl -n starfleet create configmap convergence-report \
  --from-literal=probe-progressing-reason=ProgressDeadlineExceeded \
  --from-literal=probe-bad-image=mccutchen/go-httpbin:2.25.0-does-not-exist \
  --from-literal=scout-pod-reason=Unschedulable \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl -n starfleet set image deployment/probe probe=mccutchen/go-httpbin:2.25.0
kubectl -n starfleet patch deployment scout -p '{"spec":{"template":{"spec":{"containers":[{"name":"scout","resources":{"requests":{"cpu":"10m"},"limits":{"cpu":"100m"}}}]}}}}'

for name in probe scout; do
  kubectl -n starfleet rollout status "deployment/${name}" --timeout=180s
done
echo "[solution] Applied."
