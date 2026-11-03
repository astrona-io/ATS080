#!/usr/bin/env bash
# Check: the ConfigMap owner-chain holds the live values: Deployment uid,
# ReplicaSet name, pod owner kind and observedGeneration.
set -uo pipefail

if ! kubectl -n starfleet get configmap owner-chain >/dev/null 2>&1; then
  echo "FAIL: the ConfigMap owner-chain does not exist in starfleet"
  exit 1
fi

read_key() {
  kubectl -n starfleet get configmap owner-chain -o jsonpath="{.data.$1}" 2>/dev/null
}

expected_uid="$(kubectl -n starfleet get deployment scout -o jsonpath='{.metadata.uid}' 2>/dev/null)"
expected_observed="$(kubectl -n starfleet get deployment scout -o jsonpath='{.status.observedGeneration}' 2>/dev/null)"
expected_replicaset="$(kubectl -n starfleet get pods -l app=scout -o json 2>/dev/null | jq -r '[.items[] | select(.metadata.deletionTimestamp == null) | .metadata.ownerReferences[0].name] | unique | .[0]')"

actual="$(read_key 'deployment-uid')"
if [ "$actual" != "$expected_uid" ]; then
  echo "FAIL: deployment-uid is '${actual}', expected the uid of the Deployment scout"
  exit 1
fi

actual="$(read_key 'replicaset')"
if [ "$actual" != "$expected_replicaset" ]; then
  echo "FAIL: replicaset is '${actual}', expected the owner of the scout pods ('${expected_replicaset}')"
  exit 1
fi

actual="$(read_key 'pod-owner-kind')"
if [ "$actual" != "ReplicaSet" ]; then
  echo "FAIL: pod-owner-kind is '${actual}', expected ReplicaSet"
  exit 1
fi

actual="$(read_key 'observed-generation')"
if [ "$actual" != "$expected_observed" ]; then
  echo "FAIL: observed-generation is '${actual}', expected the current status.observedGeneration (${expected_observed})"
  exit 1
fi

echo "PASS: owner-chain matches the live ownership chain"
