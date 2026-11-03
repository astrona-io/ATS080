#!/usr/bin/env bash
# Check: a ValidatingAdmissionPolicy with a binding (validationActions Deny)
# rejects tier prod in outpost (no label) and allows it in starfleet (label
# platform.example/prod-allowed=true). Uses server-side dry runs.
set -uo pipefail

if [ "$(kubectl get validatingadmissionpolicy -o json 2>/dev/null | jq '[.items[] | select(any(.spec.matchConstraints.resourceRules[]?; (.resources // []) | index("environments") != null))] | length')" -lt 1 ]; then
  echo "FAIL: no ValidatingAdmissionPolicy matches the resource environments"
  exit 1
fi

if [ "$(kubectl get validatingadmissionpolicybinding -o json 2>/dev/null | jq '[.items[] | select((.spec.validationActions // []) | index("Deny") != null)] | length')" -lt 1 ]; then
  echo "FAIL: no ValidatingAdmissionPolicyBinding with validationActions Deny exists"
  exit 1
fi

prod() {
  printf 'apiVersion: platform.example/v1alpha1\nkind: Environment\nmetadata:\n  name: grader-prod\n  namespace: %s\nspec:\n  tier: prod\n  owner: scout-team\n  replicas: 2\n' "$1"
}

allowed=""
for attempt in 1 2 3 4 5 6 7 8 9 10; do
  if prod starfleet | kubectl create --dry-run=server -f - >/dev/null 2>&1; then
    allowed=yes
    break
  fi
  sleep 2
done
if [ "$allowed" != "yes" ]; then
  echo "FAIL: a valid prod Environment in starfleet was rejected"
  exit 1
fi

denied=""
for attempt in 1 2 3 4 5 6 7 8 9 10; do
  if ! prod outpost | kubectl create --dry-run=server -f - >/dev/null 2>&1; then
    denied=yes
    break
  fi
  sleep 2
done
if [ "$denied" != "yes" ]; then
  echo "FAIL: a prod Environment in outpost was accepted. The policy or its binding does not deny it yet"
  exit 1
fi

if ! prod outpost | sed 's/tier: prod/tier: dev/' | kubectl create --dry-run=server -f - >/dev/null 2>&1; then
  echo "FAIL: a dev Environment in outpost was rejected. The policy must only restrict tier prod"
  exit 1
fi

echo "PASS: prod is allowed only in namespaces labeled platform.example/prod-allowed=true"
