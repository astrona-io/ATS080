#!/usr/bin/env bash
# Check: the XRD xdepots.platform.starfleet.example is Established and defines
# the claim Depot with a replicas integer limited to 1..3.
set -uo pipefail

xrd="$(kubectl get xrd xdepots.platform.starfleet.example -o json 2>/dev/null)"
if [ -z "$xrd" ]; then
  echo "FAIL: XRD xdepots.platform.starfleet.example does not exist"
  exit 1
fi
established="$(printf '%s' "$xrd" | jq -r '[.status.conditions[]? | select(.type=="Established" and .status=="True")] | length')"
group="$(printf '%s' "$xrd" | jq -r '.spec.group')"
kind="$(printf '%s' "$xrd" | jq -r '.spec.names.kind')"
claim="$(printf '%s' "$xrd" | jq -r '.spec.claimNames.kind // "none"')"
version="$(printf '%s' "$xrd" | jq -r '[.spec.versions[] | select(.name=="v1alpha1")] | length')"
min="$(printf '%s' "$xrd" | jq -r '.spec.versions[0].schema.openAPIV3Schema.properties.spec.properties.replicas.minimum // "none"')"
max="$(printf '%s' "$xrd" | jq -r '.spec.versions[0].schema.openAPIV3Schema.properties.spec.properties.replicas.maximum // "none"')"
if [ "$established" != "1" ]; then
  echo "FAIL: the XRD is not Established"
  exit 1
fi
if [ "$group" != "platform.starfleet.example" ] || [ "$kind" != "XDepot" ] || [ "$claim" != "Depot" ] || [ "$version" != "1" ]; then
  echo "FAIL: group=$group kind=$kind claim=$claim v1alpha1-versions=$version"
  exit 1
fi
if [ "$min" != "1" ] || [ "$max" != "3" ]; then
  echo "FAIL: replicas minimum=$min maximum=$max, expected 1 and 3"
  exit 1
fi
echo "PASS: XRD defines XDepot and the claim Depot with replicas 1 to 3"
