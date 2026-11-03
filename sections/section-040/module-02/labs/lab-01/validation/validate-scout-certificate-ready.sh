#!/usr/bin/env bash
# Check: scout-cert is Ready, refers to an Issuer in starfleet and lists both DNS names.
set -uo pipefail
fail=0

ready=""
for _ in $(seq 1 40); do
  ready="$(kubectl -n starfleet get certificate scout-cert -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)"
  [ "$ready" = "True" ] && break
  sleep 3
done
if [ "$ready" != "True" ]; then
  echo "FAIL: Certificate scout-cert in starfleet is not Ready (status: ${ready:-missing})"
  exit 1
fi
kind="$(kubectl -n starfleet get certificate scout-cert -o jsonpath='{.spec.issuerRef.kind}' 2>/dev/null)"
issuer="$(kubectl -n starfleet get certificate scout-cert -o jsonpath='{.spec.issuerRef.name}' 2>/dev/null)"
if [ "$kind" != "Issuer" ] || ! kubectl -n starfleet get issuer "$issuer" >/dev/null 2>&1; then
  echo "FAIL: scout-cert must use an Issuer that exists in starfleet (found $kind/$issuer)"
  fail=1
fi
if [ "$(kubectl -n starfleet get issuer "$issuer" -o jsonpath='{.spec.selfSigned}' 2>/dev/null)" = "" ]; then
  echo "FAIL: the Issuer $issuer must be a selfSigned Issuer"
  fail=1
fi
names="$(kubectl -n starfleet get certificate scout-cert -o jsonpath='{.spec.dnsNames[*]}' 2>/dev/null)"
for want in scout.starfleet.svc scout.starfleet.svc.cluster.local; do
  if ! echo " $names " | grep -q " $want "; then
    echo "FAIL: dnsNames of scout-cert must include $want"
    fail=1
  fi
done
if [ "$fail" -eq 0 ]; then
  echo "PASS: scout-cert is Ready with the expected issuer and names"
fi
exit "$fail"
