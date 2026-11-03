#!/usr/bin/env bash
# Check: the probe Deployment runs and mounts the Secret probe-tls.
set -uo pipefail
fail=0

secret="$(kubectl -n starfleet get deployment probe -o jsonpath='{.spec.template.spec.volumes[?(@.name=="tls")].secret.secretName}' 2>/dev/null)"
if [ "$secret" != "probe-tls" ]; then
  echo "FAIL: the volume tls of Deployment probe uses the Secret '${secret:-none}', expected probe-tls"
  exit 1
fi
mount="$(kubectl -n starfleet get deployment probe -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[?(@.name=="tls")].mountPath}' 2>/dev/null)"
if [ "$mount" != "/etc/probe/tls" ]; then
  echo "FAIL: the container must still mount the volume tls at /etc/probe/tls"
  fail=1
fi
for _ in $(seq 1 40); do
  available="$(kubectl -n starfleet get deployment probe -o jsonpath='{.status.availableReplicas}' 2>/dev/null)"
  [ "${available:-0}" = "1" ] && break
  sleep 3
done
if [ "${available:-0}" != "1" ]; then
  echo "FAIL: Deployment probe has no available replica"
  fail=1
fi
if [ "$fail" -eq 0 ]; then
  echo "PASS: probe runs with the Secret probe-tls"
fi
exit "$fail"
