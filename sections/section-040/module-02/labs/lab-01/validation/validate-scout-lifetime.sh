#!/usr/bin/env bash
# Check: the issued certificate lives 48 hours and the renewal time is 12 hours before the end.
set -uo pipefail
fail=0

for _ in $(seq 1 40); do
  ready="$(kubectl -n starfleet get certificate scout-cert -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)"
  issuing="$(kubectl -n starfleet get certificate scout-cert -o jsonpath='{.status.conditions[?(@.type=="Issuing")].status}' 2>/dev/null)"
  [ "$ready" = "True" ] && [ "$issuing" != "True" ] && break
  sleep 3
done
status="$(kubectl -n starfleet get certificate scout-cert -o json 2>/dev/null)"
not_before="$(jq -r '.status.notBefore // empty' <<<"$status")"
not_after="$(jq -r '.status.notAfter // empty' <<<"$status")"
renewal="$(jq -r '.status.renewalTime // empty' <<<"$status")"
if [ -z "$not_before" ] || [ -z "$not_after" ] || [ -z "$renewal" ]; then
  echo "FAIL: scout-cert has no notBefore, notAfter and renewalTime in its status yet"
  exit 1
fi
lifetime="$(jq -n --arg a "$not_after" --arg b "$not_before" '($a|fromdateiso8601) - ($b|fromdateiso8601)')"
lead="$(jq -n --arg a "$not_after" --arg r "$renewal" '($a|fromdateiso8601) - ($r|fromdateiso8601)')"
if [ "$lifetime" != "172800" ]; then
  echo "FAIL: the certificate is valid for $lifetime seconds, expected 172800 (48h)"
  fail=1
fi
if [ "$lead" != "43200" ]; then
  echo "FAIL: renewal starts $lead seconds before expiry, expected 43200 (12h)"
  fail=1
fi
if [ "$fail" -eq 0 ]; then
  echo "PASS: 48h lifetime and 12h renewal window"
fi
exit "$fail"
