#!/usr/bin/env bash
# Check: the Roles in starfleet that touch the platform.example group use no
# wildcard and do not grant databaseclaims/status, no Role grants the three
# groups anything through a wildcard, and no ClusterRoleBinding names
# team-starfleet, auditors or team-outpost.
set -uo pipefail

roles="$(kubectl -n starfleet get roles -o json 2>/dev/null)"
if [ -z "$roles" ]; then
  echo "FAIL: could not list the Roles in starfleet"
  exit 1
fi

wild="$(printf '%s' "$roles" | jq -r '
  .items[] | .metadata.name as $role | .rules[]?
  | select(((.apiGroups // []) | index("platform.example")) != null or ((.apiGroups // []) | index("*")) != null)
  | select(((.verbs // []) | index("*")) != null or ((.resources // []) | index("*")) != null or ((.apiGroups // []) | index("*")) != null)
  | $role')"
if [ -n "$wild" ]; then
  echo "FAIL: a Role uses a wildcard for the platform.example group: $(printf '%s' "$wild" | sort -u | tr '\n' ' ')"
  exit 1
fi

status_grant="$(printf '%s' "$roles" | jq -r '
  .items[] | .metadata.name as $role | .rules[]?
  | select(((.apiGroups // []) | index("platform.example")) != null)
  | select(((.resources // []) | map(select(startswith("databaseclaims/"))) | length) > 0)
  | $role')"
if [ -n "$status_grant" ]; then
  echo "FAIL: a Role grants a databaseclaims subresource: $(printf '%s' "$status_grant" | sort -u | tr '\n' ' ')"
  exit 1
fi

cluster_bound="$(kubectl get clusterrolebindings -o json 2>/dev/null | jq -r '
  .items[] | select(((.subjects // []) | map(select(.kind == "Group" and (.name == "team-starfleet" or .name == "auditors" or .name == "team-outpost"))) | length) > 0)
  | .metadata.name')"
if [ -n "$cluster_bound" ]; then
  echo "FAIL: a ClusterRoleBinding names a tenant group: $(printf '%s' "$cluster_bound" | tr '\n' ' '). Use RoleBindings in starfleet"
  exit 1
fi

echo "PASS: the Roles are scoped to named verbs and resources and no ClusterRoleBinding names the groups"
