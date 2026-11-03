#!/usr/bin/env bash
# Check: status written through the main endpoint is ignored, status written
# through the status subresource is stored, and the schema rejects a condition
# status outside True, False and Unknown. Creates grader-status in starfleet
# and deletes it again on exit.
set -uo pipefail

cleanup() { kubectl -n starfleet delete environment grader-status --ignore-not-found >/dev/null 2>&1; }
trap cleanup EXIT

if ! printf 'apiVersion: platform.example/v1alpha1\nkind: Environment\nmetadata:\n  name: grader-status\n  namespace: starfleet\nspec:\n  tier: dev\n  owner: scout-team\n' | kubectl create -f - >/dev/null 2>&1; then
  echo "FAIL: could not create an Environment to test the status subresource"
  exit 1
fi

kubectl -n starfleet patch environment grader-status --type=merge -p '{"status":{"phase":"FromMainEndpoint"}}' >/dev/null 2>&1
phase="$(kubectl -n starfleet get environment grader-status -o jsonpath='{.status.phase}' 2>/dev/null)"
if [ -n "$phase" ]; then
  echo "FAIL: the main endpoint accepted status ('${phase}'). Enable the status subresource"
  exit 1
fi

if ! kubectl -n starfleet patch environment grader-status --subresource=status --type=merge -p '{"status":{"phase":"Ready","observedGeneration":1}}' >/dev/null 2>&1; then
  echo "FAIL: writing status through the status subresource failed"
  exit 1
fi
phase="$(kubectl -n starfleet get environment grader-status -o jsonpath='{.status.phase}' 2>/dev/null)"
if [ "$phase" != "Ready" ]; then
  echo "FAIL: status.phase is '${phase}' after the subresource write, expected Ready"
  exit 1
fi

if kubectl -n starfleet patch environment grader-status --subresource=status --type=merge -p '{"status":{"conditions":[{"type":"Ready","status":"Maybe"}]}}' >/dev/null 2>&1; then
  echo "FAIL: the schema accepted the condition status Maybe"
  exit 1
fi

echo "PASS: status is written only through the subresource and conditions are validated"
