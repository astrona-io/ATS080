#!/usr/bin/env bash
# Check: probe-cert is Ready with both names, and the Secret probe-tls was issued.
set -uo pipefail
fail=0

for _ in $(seq 1 40); do
  ready="$(kubectl -n starfleet get certificate probe-cert -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)"
  [ "$ready" = "True" ] && break
  sleep 3
done
if [ "$ready" != "True" ]; then
  message="$(kubectl -n starfleet get certificate probe-cert -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}' 2>/dev/null)"
  echo "FAIL: Certificate probe-cert is not Ready: ${message:-no condition yet}"
  exit 1
fi
cert="$(kubectl -n starfleet get certificate probe-cert -o json)"
if [ "$(jq -r '.spec.issuerRef.kind + "/" + .spec.issuerRef.name' <<<"$cert")" != "ClusterIssuer/starfleet-ca" ]; then
  echo "FAIL: probe-cert must use ClusterIssuer/starfleet-ca"
  fail=1
fi
if [ "$(jq -r '.spec.secretName' <<<"$cert")" != "probe-tls" ]; then
  echo "FAIL: probe-cert must write the Secret probe-tls"
  fail=1
fi
for name in probe.starfleet.svc probe.starfleet.svc.cluster.local; do
  if ! jq -e --arg n "$name" '.spec.dnsNames | index($n)' <<<"$cert" >/dev/null; then
    echo "FAIL: dnsNames of probe-cert must contain $name"
    fail=1
  fi
done
secret="$(kubectl -n starfleet get secret probe-tls -o json 2>/dev/null)"
if [ -z "$secret" ] || [ "$(jq -r '.type' <<<"$secret")" != "kubernetes.io/tls" ]; then
  echo "FAIL: Secret probe-tls must exist with type kubernetes.io/tls"
  fail=1
else
  alt="$(jq -r '.metadata.annotations["cert-manager.io/alt-names"] // ""' <<<"$secret")"
  case "$alt" in
    *probe.starfleet.svc.cluster.local*) ;;
    *) echo "FAIL: the issued certificate does not contain probe.starfleet.svc.cluster.local yet (alt-names '$alt')"; fail=1 ;;
  esac
fi
if [ "$fail" -eq 0 ]; then
  echo "PASS: probe-cert is Ready with both names"
fi
exit "$fail"
