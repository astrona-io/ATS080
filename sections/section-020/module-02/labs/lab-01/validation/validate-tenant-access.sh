#!/usr/bin/env bash
# Check: kubectl auth can-i answers for three impersonated identities.
#   jean-luc in team-starfleet: full verbs on databaseclaims in starfleet, no
#     status write, nothing in outpost, no CRD change.
#   guinan in auditors: get, list and watch only.
#   worf in team-outpost: nothing in starfleet.
# Each answer is retried for a few seconds.
set -uo pipefail

answer() {
  local verb="$1" resource="$2" namespace="$3" user="$4" group="$5" subresource="${6:-}" result attempt
  local args=(auth can-i "$verb" "$resource" --as="$user" --as-group="$group")
  [ -n "$namespace" ] && args+=(-n "$namespace")
  [ -n "$subresource" ] && args+=(--subresource="$subresource")
  result="$(kubectl "${args[@]}" 2>/dev/null)"
  printf '%s' "$result"
}

expect() {
  local want="$1" label="$2" got attempt
  shift 2
  for attempt in 1 2 3 4 5 6; do
    got="$(answer "$@")"
    [ "$got" = "$want" ] && return 0
    sleep 2
  done
  echo "FAIL: ${label}: expected '${want}', got '${got}'"
  exit 1
}

claims="databaseclaims.platform.example"

for verb in create get list watch update patch delete; do
  expect yes "team-starfleet may ${verb} claims in starfleet" "$verb" "$claims" starfleet jean-luc team-starfleet
done
expect no "team-starfleet must not update status" update "$claims" starfleet jean-luc team-starfleet status
expect no "team-starfleet must not patch status" patch "$claims" starfleet jean-luc team-starfleet status
expect no "team-starfleet must not create claims in outpost" create "$claims" outpost jean-luc team-starfleet
expect no "team-starfleet must not change the CRD" delete customresourcedefinitions.apiextensions.k8s.io "" jean-luc team-starfleet

for verb in get list watch; do
  expect yes "auditors may ${verb} claims in starfleet" "$verb" "$claims" starfleet guinan auditors
done
for verb in create update patch delete; do
  expect no "auditors must not ${verb} claims in starfleet" "$verb" "$claims" starfleet guinan auditors
done

expect no "team-outpost must not read claims in starfleet" get "$claims" starfleet worf team-outpost
expect no "team-outpost must not create claims in starfleet" create "$claims" starfleet worf team-outpost

echo "PASS: tenant access matches the contract and status writes are not granted to tenants"
