#!/usr/bin/env bash
# Check: probe converged, its readiness probe still exists and uses a path that
# the container answers with HTTP 200 (go-httpbin: /get), and every live pod is
# ready. Rejects the plausible wrong fix of removing the readiness probe.
set -uo pipefail

# converged_problem NAME: prints a reason and returns 1 when the Deployment is
# not complete. Prints nothing and returns 0 when it is.
converged_problem() {
  local json problem
  json="$(kubectl -n starfleet get deployment "$1" -o json 2>/dev/null)"
  if [ -z "$json" ]; then
    echo "the Deployment $1 does not exist in starfleet"
    return 1
  fi
  problem="$(printf '%s' "$json" | jq -r '
    if (.metadata.generation != (.status.observedGeneration // 0)) then "observedGeneration \(.status.observedGeneration // 0) is not equal to generation \(.metadata.generation)"
    elif ((.status.updatedReplicas // 0) != .spec.replicas) then "\(.status.updatedReplicas // 0) of \(.spec.replicas) replicas are updated"
    elif ((.status.availableReplicas // 0) != .spec.replicas) then "\(.status.availableReplicas // 0) of \(.spec.replicas) replicas are available"
    elif ((.status.replicas // 0) != .spec.replicas) then "\(.status.replicas // 0) pods exist, expected \(.spec.replicas)"
    elif ([.status.conditions[]? | select(.type == "Available" and .status == "True")] | length) != 1 then "the Available condition is not True"
    elif ([.status.conditions[]? | select(.type == "Progressing" and .status == "True" and .reason == "NewReplicaSetAvailable")] | length) != 1 then "the Progressing condition is not True with the reason NewReplicaSetAvailable"
    else "" end')"
  if [ -n "$problem" ]; then
    echo "$problem"
    return 1
  fi
  return 0
}

# wait_converged NAME: waits up to 90 seconds for the Deployment to complete.
wait_converged() {
  local problem=""
  for attempt in $(seq 1 18); do
    if problem="$(converged_problem "$1")"; then
      return 0
    fi
    sleep 5
  done
  echo "FAIL: $1 has not converged: ${problem}"
  return 1
}

wait_converged probe || exit 1

path="$(kubectl -n starfleet get deployment probe -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.path}' 2>/dev/null)"
if [ -z "$path" ]; then
  echo "FAIL: the probe Deployment has no readiness probe with an httpGet path. Fix the path, do not remove the probe."
  exit 1
fi
case "$path" in
  /get|/status/200|/headers|/ip|/uuid) ;;
  *) echo "FAIL: the readiness path '${path}' is not one that go-httpbin answers with 200 (use /get)"; exit 1 ;;
esac

not_ready="$(kubectl -n starfleet get pods -l app=probe -o json 2>/dev/null | jq '[.items[] | select(.metadata.deletionTimestamp == null) | select(([.status.conditions[]? | select(.type == "Ready" and .status == "True")] | length) != 1)] | length')"
if [ "$not_ready" != "0" ]; then
  echo "FAIL: a probe pod is not ready"
  exit 1
fi

echo "PASS: probe converged with a working readiness probe (${path})"
