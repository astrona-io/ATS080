#!/usr/bin/env bash
# Check: the CRD environments.platform.example exists, is namespaced, has the
# kind Environment, has the single version v1alpha1 (served and stored), enables
# the status subresource, and defines the printer columns Tier, Owner, Phase.
set -uo pipefail

crd=""
for attempt in 1 2 3 4 5 6 7 8; do
  crd="$(kubectl get crd environments.platform.example -o json 2>/dev/null)" && [ -n "$crd" ] && break
  sleep 2
done
if [ -z "$crd" ]; then
  echo "FAIL: the CRD environments.platform.example does not exist"
  exit 1
fi

check() {
  local label="$1" filter="$2"
  if ! printf '%s' "$crd" | jq -e "$filter" >/dev/null; then
    echo "FAIL: ${label}"
    exit 1
  fi
}

check "the group must be platform.example and the kind Environment" '.spec.group == "platform.example" and .spec.names.kind == "Environment"'
check "the scope must be Namespaced" '.spec.scope == "Namespaced"'
check "the CRD must have exactly one version, v1alpha1, served and stored" '(.spec.versions | length) == 1 and .spec.versions[0].name == "v1alpha1" and .spec.versions[0].served == true and .spec.versions[0].storage == true'
check "the status subresource must be enabled" '.spec.versions[0].subresources.status != null'
check "the schema must define a status object with conditions" '.spec.versions[0].schema.openAPIV3Schema.properties.status.properties.conditions.type == "array"'
check "the printer columns Tier, Owner and Phase are required" '(.spec.versions[0].additionalPrinterColumns // []) | map(.name) | (index("Tier") != null and index("Owner") != null and index("Phase") != null)'
check "the Tier column must read .spec.tier and the Phase column .status.phase" '(.spec.versions[0].additionalPrinterColumns // []) | (map(select(.name == "Tier" and .jsonPath == ".spec.tier")) | length) == 1 and (map(select(.name == "Phase" and .jsonPath == ".status.phase")) | length) == 1'

echo "PASS: the Environment CRD has the right scope, version, status subresource and printer columns"
