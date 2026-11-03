---
estimated_duration: 30m
---

# Lab: Compose An Outpost Claim

Graded lab for the claims module. **UNTESTED:** it was built and checked with static checks only (`astrona validate`, `bash -n`, YAML parsing) and has not been run or graded on a cluster. The cluster starts with Crossplane 2.4.3, provider-kubernetes v1.4.1, function-patch-and-transform v0.11.2 and the XRD for `XOutpost` and the `Outpost` claim. The learner writes the Composition and creates the claim. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-030/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-030/module-01/labs/lab-01
astrona destroy ats-080-lab-030-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`. The machine needs `helm` 3.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-composition-pipeline.sh` | `outpost-kubernetes` targets `XOutpost`, runs in `Pipeline` mode and calls `function-patch-and-transform` |
| `validate-claim-ready.sh` | The claim `scout` has `Synced` and `Ready` set to `True` and `replicas: 2` |
| `validate-namespace-and-deployment.sh` | `outpost-scout` exists and `scout` has 2 available replicas |
| `validate-composed-objects.sh` | The composite resource owns at least two Objects (label `crossplane.io/composite`) and each is `Synced` |
| `validate-status-namespace.sh` | The composite resource reports `status.namespace: outpost-scout` |

## Known risks

- Untested: the label `crossplane.io/claim-name` on the composite resource and the label `crossplane.io/composite` on composed Objects are expected from Crossplane 2.4.3 legacy claims and were not observed.
- The bootstrap needs `helm` on the host and downloads the chart and packages. Package installation can take several minutes.
