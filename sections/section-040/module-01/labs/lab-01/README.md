---
estimated_duration: 40m
---

# Lab: Complete The Beacon Operator

Graded lab for the operator pattern module. **UNTESTED**: built with static checks only (`astrona validate`, `bash -n`, YAML parsing); it has not been run on a cluster. The cluster starts with the `Beacon` CRD, a starter operator (a bash loop in a Deployment) and two `Beacon` resources. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-040/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-040/module-01/labs/lab-01
astrona destroy ats-080-lab-040-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-child-owned-by-beacon.sh` | `beacon-scout` and `beacon-probe` have an ownerReference with the uid of their Beacon |
| `validate-status-follows-spec.sh` | status is Ready, and observedGeneration follows a change of `spec.message` |
| `validate-finalizer-cleans-registry.sh` | A temporary Beacon gets a registry entry, then deleting it removes entry, child and Beacon |
| `validate-restart-is-idempotent.sh` | Deleting the operator pod keeps the same ConfigMap uids and adds no object |
| `validate-least-privilege.sh` | `kubectl auth can-i --as` shows no Secret access and no delete outside the registry |

## Open items (UNTESTED assumptions)

- `kubectl patch --subresource=status` and `kubectl apply` of a JSON manifest work inside `alpine/k8s:1.35.8` with `HOME=/tmp`.
- The operator needs up to two loops (10 seconds) to react, so the graders wait up to about 90 seconds.
- The grader impersonates the service account with `kubectl auth can-i --as`, which needs the cluster-admin kubeconfig that kind creates.
