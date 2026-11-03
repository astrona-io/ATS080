#!/usr/bin/env bash
# Check: tier prod needs at least 2 replicas (cross-field rule), and the owner
# cannot change after creation (transition rule). The transition test creates
# the object grader-env in starfleet and deletes it again on exit.
set -uo pipefail

cleanup() { kubectl -n starfleet delete environment grader-env --ignore-not-found >/dev/null 2>&1; }
trap cleanup EXIT

manifest() {
  printf 'apiVersion: platform.example/v1alpha1\nkind: Environment\nmetadata:\n  name: grader-env\n  namespace: starfleet\nspec:\n%s\n' "$1"
}

if manifest '  tier: prod
  owner: scout-team
  replicas: 1' | kubectl create --dry-run=server -f - >/dev/null 2>&1; then
  echo "FAIL: tier prod with 1 replica was accepted"
  exit 1
fi

if ! manifest '  tier: prod
  owner: scout-team
  replicas: 2' | kubectl create --dry-run=server -f - >/dev/null 2>&1; then
  echo "FAIL: tier prod with 2 replicas in starfleet was rejected"
  exit 1
fi

if ! manifest '  tier: dev
  owner: scout-team' | kubectl create -f - >/dev/null 2>&1; then
  echo "FAIL: a valid dev Environment could not be created"
  exit 1
fi

if kubectl -n starfleet patch environment grader-env --type=merge -p '{"spec":{"owner":"drifter-team"}}' >/dev/null 2>&1; then
  echo "FAIL: the owner was changed after creation"
  exit 1
fi

if ! kubectl -n starfleet patch environment grader-env --type=merge -p '{"spec":{"replicas":3}}' >/dev/null 2>&1; then
  echo "FAIL: a valid update of replicas was rejected"
  exit 1
fi

echo "PASS: the prod rule and the owner transition rule work"
