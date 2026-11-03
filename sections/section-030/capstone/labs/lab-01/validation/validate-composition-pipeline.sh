#!/usr/bin/env bash
# Check: Composition depot-kubernetes targets XDepot in Pipeline mode with function-patch-and-transform.
set -uo pipefail

comp="$(kubectl get composition depot-kubernetes -o json 2>/dev/null)"
if [ -z "$comp" ]; then
  echo "FAIL: Composition depot-kubernetes does not exist"
  exit 1
fi
kind="$(printf '%s' "$comp" | jq -r '.spec.compositeTypeRef.kind')"
mode="$(printf '%s' "$comp" | jq -r '.spec.mode')"
fn="$(printf '%s' "$comp" | jq -r '[.spec.pipeline[]?.functionRef.name] | index("function-patch-and-transform") != null')"
if [ "$kind" != "XDepot" ] || [ "$mode" != "Pipeline" ] || [ "$fn" != "true" ]; then
  echo "FAIL: kind=$kind mode=$mode function-patch-and-transform=$fn"
  exit 1
fi
echo "PASS: depot-kubernetes is a pipeline for XDepot"
