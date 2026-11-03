#!/usr/bin/env bash
# Check: v1beta1 is the single storage version, both versions are served,
# v1alpha1 is deprecated with a warning that names v1beta1, v1beta1 is not
# deprecated, the conversion strategy is None, storedVersions lists v1beta1,
# and scout-db reads in both versions.
set -uo pipefail

crd="$(kubectl get crd databaseclaims.platform.example -o json 2>/dev/null)"
if [ -z "$crd" ]; then
  echo "FAIL: the CRD databaseclaims.platform.example does not exist"
  exit 1
fi

storage="$(printf '%s' "$crd" | jq -r '[.spec.versions[] | select(.storage == true) | .name] | join(",")')"
if [ "$storage" != "v1beta1" ]; then
  echo "FAIL: the storage version must be exactly v1beta1, found '${storage}'"
  exit 1
fi

served="$(printf '%s' "$crd" | jq -r '[.spec.versions[] | select(.served == true) | .name] | sort | join(",")')"
if [ "$served" != "v1alpha1,v1beta1" ]; then
  echo "FAIL: both versions must stay served, served versions are '${served}'"
  exit 1
fi

deprecated_alpha="$(printf '%s' "$crd" | jq -r '.spec.versions[] | select(.name == "v1alpha1") | .deprecated // false')"
deprecated_beta="$(printf '%s' "$crd" | jq -r '.spec.versions[] | select(.name == "v1beta1") | .deprecated // false')"
warning="$(printf '%s' "$crd" | jq -r '.spec.versions[] | select(.name == "v1alpha1") | .deprecationWarning // ""')"
if [ "$deprecated_alpha" != "true" ]; then
  echo "FAIL: v1alpha1 is not marked deprecated"
  exit 1
fi
if [ "$deprecated_beta" = "true" ]; then
  echo "FAIL: v1beta1 must not be deprecated"
  exit 1
fi
if ! printf '%s' "$warning" | grep -q 'v1beta1'; then
  echo "FAIL: the deprecationWarning of v1alpha1 must name the replacement version v1beta1 (found '${warning}')"
  exit 1
fi

strategy="$(printf '%s' "$crd" | jq -r '.spec.conversion.strategy // "None"')"
if [ "$strategy" != "None" ]; then
  echo "FAIL: the conversion strategy must be None, found '${strategy}'"
  exit 1
fi

if ! printf '%s' "$crd" | jq -e '.status.storedVersions | index("v1beta1")' >/dev/null; then
  echo "FAIL: status.storedVersions does not list v1beta1 yet"
  exit 1
fi

for version in v1alpha1 v1beta1; do
  api_version="$(kubectl -n starfleet get "databaseclaims.${version}.platform.example" scout-db -o jsonpath='{.apiVersion}' 2>/dev/null)"
  if [ "$api_version" != "platform.example/${version}" ]; then
    echo "FAIL: scout-db did not read as platform.example/${version} (got '${api_version}')"
    exit 1
  fi
done

echo "PASS: v1beta1 is the storage version, v1alpha1 is served and deprecated, conversion is None"
