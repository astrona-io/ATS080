---
estimated_duration: 40m
---

# Capstone Lab: Unblock A Release And Release A Stuck Deletion

Graded capstone for the reconciliation loop section. **UNTESTED:** it was built and checked with static checks only (`astrona validate`, `bash -n`, YAML parsing) and has not been run or graded on a cluster. The cluster starts with three stuck objects in `starfleet`: `scout` rolls out an image tag that does not exist, `probe` has a readiness probe that returns 404, and the ConfigMap `decommissioned-beacon` is terminating because of a finalizer. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-010/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-010/capstone/labs/lab-01
astrona destroy ats-080-capstone-010
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-scout-converged.sh` | `scout` completed (generation observed, all replicas updated and available, `Available` true, `Progressing` true with `NewReplicaSetAvailable`) and every live pod runs `ghcr.io/stefanprodan/podinfo:6.15.0` |
| `validate-probe-converged.sh` | `probe` completed, still has a readiness probe with a path that go-httpbin answers, and every live pod is ready |
| `validate-beacon-released.sh` | `decommissioned-beacon` is gone and `active-beacon` is unchanged |
| `validate-release-note.sh` | `release-note` names the live `scout` Deployment in `ownerReferences` and holds the current revision annotation and image |
| `validate-not-recreated.sh` | Every Deployment keeps the uid recorded at the start, and `shuttle` gets HTTP 200 from `scout` and `probe` |

## Known risks

- The setup waits for the Deployments to report `Progressing=False` with `kubectl wait`, with a 180 second limit each and no failure on timeout.
- The `revision` value is read from the live annotation at grading time. The learner must create `release-note` after the Deployments are fixed.
- The readiness path check accepts a short list of go-httpbin paths that return 200.
