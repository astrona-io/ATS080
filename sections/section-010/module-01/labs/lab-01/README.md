---
estimated_duration: 20m
---

# Lab: Scale A Deployment And Read The Ownership Chain

Graded lab for the control loop module. **UNTESTED:** it was built and checked with static checks only (`astrona validate`, `bash -n`, YAML parsing) and has not been run or graded on a cluster. The `starfleet` namespace starts with healthy Deployments `scout` and `probe` (two replicas each) and a `shuttle` client. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-010/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-080-lab-010-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-scout-scaled.sh` | `spec.replicas` is 4, four pods are available and `observedGeneration` equals `generation` |
| `validate-owner-chain.sh` | The ConfigMap `owner-chain` holds the live Deployment uid, ReplicaSet name, pod owner kind and `observedGeneration` |
| `validate-not-recreated.sh` | Every Deployment keeps the uid recorded at the start and `probe` still has two replicas |
| `validate-services-answer.sh` | `shuttle` gets HTTP 200 from the `scout` and `probe` Services |

## Known risks

- The grader reads the ReplicaSet name from the live pods, so it assumes that all `scout` pods belong to one ReplicaSet after the scale (the pod template does not change).
- The baseline ConfigMap `lab-baseline` in `lab-support` is visible to the learner. It only records uids.
