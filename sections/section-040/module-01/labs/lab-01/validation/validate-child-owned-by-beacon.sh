#!/usr/bin/env bash
# Check: each child ConfigMap has an ownerReference to its Beacon with the right uid.
set -uo pipefail
fail=0

check_child() {
  local name="$1" beacon_uid owner_uid owner_kind owner_name controller
  beacon_uid="$(kubectl -n starfleet get beacon "$name" -o jsonpath='{.metadata.uid}' 2>/dev/null)"
  if [ -z "$beacon_uid" ]; then
    echo "FAIL: Beacon $name does not exist"
    fail=1
    return
  fi
  for _ in $(seq 1 30); do
    owner_uid="$(kubectl -n starfleet get configmap "beacon-$name" -o jsonpath='{.metadata.ownerReferences[0].uid}' 2>/dev/null)"
    [ "$owner_uid" = "$beacon_uid" ] && break
    sleep 3
  done
  owner_kind="$(kubectl -n starfleet get configmap "beacon-$name" -o jsonpath='{.metadata.ownerReferences[0].kind}' 2>/dev/null)"
  owner_name="$(kubectl -n starfleet get configmap "beacon-$name" -o jsonpath='{.metadata.ownerReferences[0].name}' 2>/dev/null)"
  controller="$(kubectl -n starfleet get configmap "beacon-$name" -o jsonpath='{.metadata.ownerReferences[0].controller}' 2>/dev/null)"
  if [ "$owner_uid" != "$beacon_uid" ]; then
    echo "FAIL: ConfigMap beacon-$name has no ownerReference with the uid of Beacon $name"
    fail=1
  elif [ "$owner_kind" != "Beacon" ] || [ "$owner_name" != "$name" ]; then
    echo "FAIL: the ownerReference of beacon-$name must name kind Beacon and name $name (found $owner_kind/$owner_name)"
    fail=1
  elif [ "$controller" != "true" ]; then
    echo "FAIL: the ownerReference of beacon-$name must have controller: true"
    fail=1
  fi
}

check_child scout
check_child probe
if [ "$fail" -eq 0 ]; then
  echo "PASS: child ConfigMaps are owned by their Beacons"
fi
exit "$fail"
