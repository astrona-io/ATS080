#!/usr/bin/env bash
# Check: kubectl auth can-i for impersonated identities. Each team manages
# environments in its own namespace only, nobody gets status, auditors read in
# both namespaces. Also no wildcard, no environments/status grant and no
# ClusterRoleBinding for the three groups.
set -uo pipefail

res="environments.platform.example"

answer() {
  local verb="$1" namespace="$2" user="$3" group="$4" subresource="${5:-}"
  local args=(auth can-i "$verb" "$res" -n "$namespace" --as="$user" --as-group="$group")
  [ -n "$subresource" ] && args+=(--subresource="$subresource")
  kubectl "${args[@]}" 2>/dev/null
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

for verb in create get list watch update patch delete; do
  expect yes "team-starfleet may ${verb} in starfleet" "$verb" starfleet jean-luc team-starfleet
  expect yes "team-outpost may ${verb} in outpost" "$verb" outpost worf team-outpost
done
expect no "team-starfleet must not create in outpost" create outpost jean-luc team-starfleet
expect no "team-outpost must not create in starfleet" create starfleet worf team-outpost
expect no "team-outpost must not read in starfleet" get starfleet worf team-outpost
expect no "team-starfleet must not update status" update starfleet jean-luc team-starfleet status
expect no "team-outpost must not patch status" patch outpost worf team-outpost status

for namespace in starfleet outpost; do
  for verb in get list watch; do
    expect yes "auditors may ${verb} in ${namespace}" "$verb" "$namespace" guinan auditors
  done
  for verb in create update patch delete; do
    expect no "auditors must not ${verb} in ${namespace}" "$verb" "$namespace" guinan auditors
  done
done

for namespace in starfleet outpost; do
  bad="$(kubectl -n "$namespace" get roles -o json 2>/dev/null | jq -r '
    .items[] | .metadata.name as $role | .rules[]?
    | select(((.apiGroups // []) | index("platform.example")) != null or ((.apiGroups // []) | index("*")) != null)
    | select(((.verbs // []) | index("*")) != null or ((.resources // []) | index("*")) != null or ((.apiGroups // []) | index("*")) != null or (((.resources // []) | map(select(startswith("environments/"))) | length) > 0))
    | $role')"
  if [ -n "$bad" ]; then
    echo "FAIL: a Role in ${namespace} uses a wildcard or grants environments/status: $(printf '%s' "$bad" | sort -u | tr '\n' ' ')"
    exit 1
  fi
done

cluster_bound="$(kubectl get clusterrolebindings -o json 2>/dev/null | jq -r '
  .items[] | select(((.subjects // []) | map(select(.kind == "Group" and (.name == "team-starfleet" or .name == "auditors" or .name == "team-outpost"))) | length) > 0)
  | .metadata.name')"
if [ -n "$cluster_bound" ]; then
  echo "FAIL: a ClusterRoleBinding names a tenant group: $(printf '%s' "$cluster_bound" | tr '\n' ' ')"
  exit 1
fi

echo "PASS: tenant access is scoped to each namespace and tenants cannot write status"
