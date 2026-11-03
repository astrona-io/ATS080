#!/usr/bin/env bash
# Check: release-note exists, names the live scout Deployment as owner (kind,
# apiVersion, name and uid), and records the current revision annotation and
# the image of the scout pods. A wrong uid makes the garbage collector delete
# the note, so the check also covers that case.
set -uo pipefail

note="$(kubectl -n starfleet get configmap release-note -o json 2>/dev/null)"
if [ -z "$note" ]; then
  echo "FAIL: the ConfigMap release-note does not exist in starfleet (a wrong owner uid makes the garbage collector delete it)"
  exit 1
fi

live_uid="$(kubectl -n starfleet get deployment scout -o jsonpath='{.metadata.uid}' 2>/dev/null)"
matches="$(printf '%s' "$note" | jq --arg uid "$live_uid" '[.metadata.ownerReferences[]? | select(.apiVersion == "apps/v1" and .kind == "Deployment" and .name == "scout" and .uid == $uid)] | length')"
if [ "$matches" != "1" ]; then
  echo "FAIL: release-note has no ownerReferences entry for apps/v1 Deployment scout with the live uid"
  exit 1
fi

live_revision="$(kubectl -n starfleet get deployment scout -o jsonpath='{.metadata.annotations.deployment\.kubernetes\.io/revision}' 2>/dev/null)"
revision="$(printf '%s' "$note" | jq -r '.data.revision // ""')"
if [ "$revision" != "$live_revision" ]; then
  echo "FAIL: revision is '${revision}', expected the current annotation value '${live_revision}'"
  exit 1
fi

image="$(printf '%s' "$note" | jq -r '.data.image // ""')"
if [ "$image" != "ghcr.io/stefanprodan/podinfo:6.15.0" ]; then
  echo "FAIL: image is '${image}', expected ghcr.io/stefanprodan/podinfo:6.15.0"
  exit 1
fi

echo "PASS: release-note is owned by scout and records revision ${revision}"
