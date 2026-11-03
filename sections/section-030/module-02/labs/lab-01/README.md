---
estimated_duration: 35m
---

# Lab: Fix Identity, Connection Secret And Deletion Behavior

Graded lab for the providers module. **UNTESTED:** it was built and checked with static checks only (`astrona validate`, `bash -n`, YAML parsing) and has not been run or graded on a cluster. The cluster starts with a finished `Outpost` claim API and two claims, `scout` and `probe`. The provider identity cannot create Deployments, `scout` has no connection secret and the record ConfigMap is deleted with its claim. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-030/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-030/module-02/labs/lab-01
astrona destroy ats-080-lab-030-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`. The machine needs `helm` 3.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-identity-least-privilege.sh` | The provider service account can create Deployments, is not bound to `cluster-admin` and cannot delete nodes |
| `validate-claims-ready.sh` | The claim `scout` is `Synced` and `Ready` and its Deployment has an available replica |
| `validate-connection-secret.sh` | `scout-conn` in `starfleet` holds `endpoint=scout.outpost-scout.svc.cluster.local:9898` |
| `validate-record-orphaned.sh` | The Composition sets `deletionPolicy: Orphan` on the `record` resource |
| `validate-probe-deleted-record-kept.sh` | `probe` and `outpost-probe` are gone and `record-probe` is still in `starfleet-records` |

## Known risks

- Untested: the exact condition messages, the claim status copy and the order in which the provider retries failed Objects were not observed.
- A composed Object created before the Composition change receives `deletionPolicy: Orphan` only after the composite resource is reconciled again. The reference solution waits up to 6 minutes for that.
- The connection secret value depends on the Object reading `data.endpoint` from a ConfigMap. This provider behavior was verified in the source code (version v1.4.1) but not run.
