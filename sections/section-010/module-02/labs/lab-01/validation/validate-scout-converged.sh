#!/usr/bin/env bash
# Check: scout pods are scheduled and running with a CPU request of at most
# 100m, and the Deployment completed. Reads the pods, so a template that was
# changed but not rolled out fails.
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

wait_converged scout || exit 1

too_big="$(kubectl -n starfleet get pods -l app=scout -o json 2>/dev/null | jq '
  def mcpu: if endswith("m") then (rtrimstr("m") | tonumber) else ((tonumber) * 1000) end;
  [.items[] | select(.metadata.deletionTimestamp == null) | (.spec.containers[0].resources.requests.cpu // "0m") | mcpu | select(. > 100)] | length')"
if [ "$too_big" != "0" ]; then
  echo "FAIL: a scout pod still requests more than 100m CPU"
  exit 1
fi

not_running="$(kubectl -n starfleet get pods -l app=scout -o json 2>/dev/null | jq '[.items[] | select(.metadata.deletionTimestamp == null) | select(.status.phase != "Running")] | length')"
if [ "$not_running" != "0" ]; then
  echo "FAIL: a scout pod is not Running"
  exit 1
fi

echo "PASS: scout converged with a CPU request of at most 100m"
