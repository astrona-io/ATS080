---
estimated_duration: 60m
---

# Capstone Lab: A Complete Self-Service API

Graded capstone for the section on APIs for self-service platforms. **UNTESTED:** it was built and checked with static checks only (`astrona validate`, `bash -n`, YAML parsing) and has not been run or graded on a cluster. The cluster starts with two namespaces and nothing else. The learner defines the `Environment` API in the group `platform.example` from the start. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-020/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-020/capstone/labs/lab-01
astrona destroy ats-080-capstone-020
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-crd-shape.sh` | Name, group, kind, scope, one version, status subresource, printer columns |
| `validate-schema-defaults.sh` | Dry-run create applies the defaults and rejects bad tier, replicas, region, ttlDays and owner |
| `validate-cel-rules.sh` | Prod needs 2 replicas, the owner is immutable (creates and deletes `grader-env`) |
| `validate-status-subresource.sh` | Main endpoint ignores status, `/status` stores it, bad condition status is rejected (creates and deletes `grader-status`) |
| `validate-tenant-rbac.sh` | `kubectl auth can-i` matrix for three groups in two namespaces, no wildcard, no status grant, no ClusterRoleBinding |
| `validate-prod-policy.sh` | Policy and Deny binding reject prod in `outpost` and allow it in `starfleet` |

## Known risks

- The API server reloads the CRD and the policy in the background, so the checks retry for about 20 seconds.
- The CEL rule on the owner needs an existing object, so the check creates and removes a temporary one.
