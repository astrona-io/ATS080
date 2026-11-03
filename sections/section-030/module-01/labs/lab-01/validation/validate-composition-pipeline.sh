#!/usr/bin/env bash
# Check: Composition outpost-kubernetes targets XOutpost, runs in Pipeline mode
# and calls function-patch-and-transform.
set -uo pipefail

comp="$(kubectl get composition outpost-kubernetes -o json 2>/dev/null)"
if [ -z "$comp" ]; then
  echo "FAIL: Composition outpost-kubernetes does not exist"
  exit 1
fi
kind="$(printf '%s' "$comp" | jq -r '.spec.compositeTypeRef.kind')"
api="$(printf '%s' "$comp" | jq -r '.spec.compositeTypeRef.apiVersion')"
mode="$(printf '%s' "$comp" | jq -r '.spec.mode')"
fn="$(printf '%s' "$comp" | jq -r '[.spec.pipeline[]?.functionRef.name] | index("function-patch-and-transform") != null')"
if [ "$kind" != "XOutpost" ] || [ "$api" != "platform.starfleet.example/v1alpha1" ]; then
  echo "FAIL: compositeTypeRef is $api $kind, expected platform.starfleet.example/v1alpha1 XOutpost"
  exit 1
fi
if [ "$mode" != "Pipeline" ] || [ "$fn" != "true" ]; then
  echo "FAIL: the Composition must use mode Pipeline with function-patch-and-transform (mode=$mode, function=$fn)"
  exit 1
fi
echo "PASS: outpost-kubernetes is a pipeline that calls function-patch-and-transform"
