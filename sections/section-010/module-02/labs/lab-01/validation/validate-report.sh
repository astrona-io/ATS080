#!/usr/bin/env bash
# Check: the ConfigMap convergence-report holds the three failure facts that
# the learner must read before the fix. The expected values are fixed by the
# bootstrap script (bad image tag) and by the controllers (reasons).
set -uo pipefail

if ! kubectl -n starfleet get configmap convergence-report >/dev/null 2>&1; then
  echo "FAIL: the ConfigMap convergence-report does not exist in starfleet"
  exit 1
fi

check_key() {
  local key="$1" expected="$2" actual
  actual="$(kubectl -n starfleet get configmap convergence-report -o jsonpath="{.data.${key}}" 2>/dev/null)"
  if [ "$actual" != "$expected" ]; then
    echo "FAIL: ${key} is '${actual}', expected '${expected}'"
    exit 1
  fi
}

check_key probe-progressing-reason ProgressDeadlineExceeded
check_key probe-bad-image mccutchen/go-httpbin:2.25.0-does-not-exist
check_key scout-pod-reason Unschedulable

echo "PASS: convergence-report holds the three recorded facts"
