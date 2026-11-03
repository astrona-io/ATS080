#!/usr/bin/env bash
# Check: status is Ready and observedGeneration follows a change of spec.message.
set -uo pipefail
fail=0

status_field() { kubectl -n starfleet get beacon scout -o jsonpath="$1" 2>/dev/null; }

for _ in $(seq 1 30); do
  [ "$(status_field '{.status.phase}')" = "Ready" ] && break
  sleep 3
done
if [ "$(status_field '{.status.phase}')" != "Ready" ]; then
  echo "FAIL: Beacon scout has no status.phase Ready"
  exit 1
fi
if [ "$(status_field '{.status.configMapName}')" != "beacon-scout" ]; then
  echo "FAIL: status.configMapName of scout must be beacon-scout"
  fail=1
fi

new_message="scout updated $(date +%s)"
kubectl -n starfleet patch beacon scout --type=merge -p "{\"spec\":{\"message\":\"$new_message\"}}" >/dev/null
generation="$(status_field '{.metadata.generation}')"
followed=0
for _ in $(seq 1 30); do
  if [ "$(status_field '{.status.observedGeneration}')" = "$generation" ]; then
    followed=1
    break
  fi
  sleep 3
done
if [ "$followed" -ne 1 ]; then
  echo "FAIL: status.observedGeneration did not reach generation $generation after a change"
  fail=1
fi
message=""
for _ in $(seq 1 10); do
  message="$(kubectl -n starfleet get configmap beacon-scout -o jsonpath='{.data.message}' 2>/dev/null)"
  [ "$message" = "$new_message" ] && break
  sleep 3
done
if [ "$message" != "$new_message" ]; then
  echo "FAIL: the child ConfigMap did not take the new message"
  fail=1
fi
if [ "$fail" -eq 0 ]; then
  echo "PASS: status follows the spec"
fi
exit "$fail"
