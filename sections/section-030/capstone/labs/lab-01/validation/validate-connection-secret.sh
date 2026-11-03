#!/usr/bin/env bash
# Check: Secret depot-conn in starfleet holds the key endpoint with the expected address.
set -uo pipefail

if ! kubectl -n starfleet get secret depot-conn >/dev/null 2>&1; then
  echo "FAIL: the Secret depot-conn does not exist in starfleet"
  exit 1
fi
value="$(kubectl -n starfleet get secret depot-conn -o jsonpath='{.data.endpoint}' | base64 -d 2>/dev/null)"
expected="scout.depot-scout-depot.svc.cluster.local:9898"
if [ "$value" != "$expected" ]; then
  echo "FAIL: key endpoint is '${value}', expected '${expected}'"
  exit 1
fi
echo "PASS: depot-conn holds endpoint=$expected"
