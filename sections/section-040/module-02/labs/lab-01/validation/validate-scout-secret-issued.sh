#!/usr/bin/env bash
# Check: Secret scout-tls was issued by cert-manager and holds a key pair.
set -uo pipefail
fail=0

for _ in $(seq 1 30); do
  kubectl -n starfleet get secret scout-tls >/dev/null 2>&1 && break
  sleep 3
done
if ! kubectl -n starfleet get secret scout-tls >/dev/null 2>&1; then
  echo "FAIL: Secret scout-tls does not exist in starfleet"
  exit 1
fi
type="$(kubectl -n starfleet get secret scout-tls -o jsonpath='{.type}')"
if [ "$type" != "kubernetes.io/tls" ]; then
  echo "FAIL: Secret scout-tls has type $type, expected kubernetes.io/tls"
  fail=1
fi
for key in tls.crt tls.key; do
  value="$(kubectl -n starfleet get secret scout-tls -o json | jq -r --arg k "$key" '.data[$k] // ""')"
  if [ -z "$value" ]; then
    echo "FAIL: Secret scout-tls has no $key"
    fail=1
  fi
done
owner="$(kubectl -n starfleet get secret scout-tls -o jsonpath='{.metadata.annotations.cert-manager\.io/certificate-name}')"
if [ "$owner" != "scout-cert" ]; then
  echo "FAIL: Secret scout-tls was not issued for the Certificate scout-cert (annotation cert-manager.io/certificate-name is '$owner')"
  fail=1
fi
if [ "$fail" -eq 0 ]; then
  echo "PASS: Secret scout-tls holds a certificate issued for scout-cert"
fi
exit "$fail"
