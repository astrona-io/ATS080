#!/usr/bin/env bash
# Check: drifter-cert in outpost is Ready and still uses the Issuer outpost-issuer.
set -uo pipefail
fail=0

ready=""
for _ in $(seq 1 40); do
  ready="$(kubectl -n outpost get certificate drifter-cert -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)"
  [ "$ready" = "True" ] && break
  sleep 3
done
if [ "$ready" != "True" ]; then
  echo "FAIL: Certificate drifter-cert in outpost is not Ready"
  echo "message: $(kubectl -n outpost get certificate drifter-cert -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}' 2>/dev/null)"
  exit 1
fi
name="$(kubectl -n outpost get certificate drifter-cert -o jsonpath='{.spec.issuerRef.name}')"
kind="$(kubectl -n outpost get certificate drifter-cert -o jsonpath='{.spec.issuerRef.kind}')"
if [ "$name" != "outpost-issuer" ] || [ "$kind" != "Issuer" ]; then
  echo "FAIL: drifter-cert must keep issuerRef Issuer/outpost-issuer (found $kind/$name)"
  fail=1
fi
if ! kubectl -n outpost get secret drifter-tls >/dev/null 2>&1; then
  echo "FAIL: Secret drifter-tls does not exist"
  fail=1
fi
if [ "$fail" -eq 0 ]; then
  echo "PASS: drifter-cert is Ready"
fi
exit "$fail"
