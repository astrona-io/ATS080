#!/usr/bin/env bash
# Check: the API server rejects a Depot with replicas 5 and accepts one with replicas 3.
set -uo pipefail

bad="$(printf '%s\n' 'apiVersion: platform.starfleet.example/v1alpha1' 'kind: Depot' 'metadata:' '  name: bounds-test' '  namespace: starfleet' 'spec:' '  replicas: 5' | kubectl create --dry-run=server -f - 2>&1)"
if [ $? -eq 0 ]; then
  echo "FAIL: the API server accepted a Depot with replicas 5"
  exit 1
fi
good="$(printf '%s\n' 'apiVersion: platform.starfleet.example/v1alpha1' 'kind: Depot' 'metadata:' '  name: bounds-test' '  namespace: starfleet' 'spec:' '  replicas: 3' | kubectl create --dry-run=server -f - 2>&1)"
if [ $? -ne 0 ]; then
  echo "FAIL: the API server rejected a Depot with replicas 3: $good"
  exit 1
fi
echo "PASS: replicas 5 is rejected and replicas 3 is accepted"
