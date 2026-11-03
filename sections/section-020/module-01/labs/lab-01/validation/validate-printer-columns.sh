#!/usr/bin/env bash
# Check: the CRD defines the printer columns Engine, Environment and Phase with
# the JSON paths of the spec and status fields, and kubectl get shows them.
set -uo pipefail

columns="$(kubectl get crd databaseclaims.platform.example -o json 2>/dev/null \
  | jq -r '.spec.versions[] | select(.name == "v1alpha1") | .additionalPrinterColumns // [] | .[] | "\(.name)=\(.jsonPath)"' 2>/dev/null)"

for expected in "Engine=.spec.engine" "Environment=.spec.environment" "Phase=.status.phase"; do
  if ! printf '%s\n' "$columns" | grep -qxF "$expected"; then
    echo "FAIL: missing printer column '${expected}' (found: $(printf '%s' "$columns" | tr '\n' ' '))"
    exit 1
  fi
done

header=""
for attempt in 1 2 3 4 5 6 7 8 9 10; do
  header="$(kubectl -n starfleet get databaseclaims 2>/dev/null | head -1 | tr '[:lower:]' '[:upper:]')"
  if printf '%s' "$header" | grep -q 'ENGINE' && printf '%s' "$header" | grep -q 'ENVIRONMENT' && printf '%s' "$header" | grep -q 'PHASE'; then
    echo "PASS: kubectl get shows the columns Engine, Environment and Phase"
    exit 0
  fi
  sleep 2
done
echo "FAIL: the kubectl get header is '${header}'"
exit 1
