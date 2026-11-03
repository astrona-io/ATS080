---
estimated_duration: 50m
---

# Capstone: Build A Complete Claim API

Capstone for the infrastructure provisioning section. **UNTESTED:** it was built and checked with static checks only (`astrona validate`, `bash -n`, YAML parsing) and has not been run or graded on a cluster. The cluster starts with Crossplane 2.4.3, provider-kubernetes v1.4.1 (bound to `cluster-admin`) and function-patch-and-transform v0.11.2. The learner writes the XRD, the Composition and the claims, and proves the deletion behavior. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-030/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-030/capstone/labs/lab-01
astrona destroy ats-080-capstone-030
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`. The machine needs `helm` 3.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-claim-api.sh` | The XRD is `Established` with `XDepot`, claim `Depot`, `v1alpha1` and `replicas` from 1 to 3 |
| `validate-composition-pipeline.sh` | `depot-kubernetes` targets `XDepot` in `Pipeline` mode with `function-patch-and-transform` |
| `validate-scout-depot-ready.sh` | `scout-depot` is `Synced` and `Ready` and `depot-scout-depot/scout` has 2 available replicas |
| `validate-connection-secret.sh` | `depot-conn` in `starfleet` holds the expected `endpoint` |
| `validate-record-kept-after-delete.sh` | `probe-depot` and `depot-probe-depot` are gone and `record-probe-depot` remains |
| `validate-claim-bounds-enforced.sh` | A server-side dry run rejects `replicas: 5` and accepts `replicas: 3` |

## Known risks

- Untested. The label `crossplane.io/claim-name`, the claim connection secret path and the timing of the `Orphan` change were not observed.
- The check `validate-claim-bounds-enforced.sh` creates nothing: it uses `--dry-run=server`.
