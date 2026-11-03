---
estimated_duration: 30m
---

# Lab: Fix Deployments That Cannot Converge

Graded lab for the convergence module. **UNTESTED:** it was built and checked with static checks only (`astrona validate`, `bash -n`, YAML parsing) and has not been run or graded on a cluster. The setup script breaks two Deployments in `starfleet`: `probe` rolls out an image tag that does not exist, and `scout` asks for a CPU request that no node can give. Both stay stuck until their progress deadline of 60 seconds passes. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-010/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-010/module-02/labs/lab-01
astrona destroy ats-080-lab-010-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-probe-converged.sh` | `probe` completed (generation observed, all replicas updated and available, `Available` true, `Progressing` true with `NewReplicaSetAvailable`) and every live pod runs `mccutchen/go-httpbin:2.25.0` |
| `validate-scout-converged.sh` | `scout` completed in the same way, every live pod is `Running` and requests at most 100m CPU |
| `validate-report.sh` | `convergence-report` holds `ProgressDeadlineExceeded`, the bad image tag and `Unschedulable` |
| `validate-not-recreated.sh` | Every Deployment keeps the uid recorded at the start and `probe` keeps `progressDeadlineSeconds: 60` |
| `validate-services-answer.sh` | `shuttle` gets HTTP 200 from the `scout` and `probe` Services |

## Known risks

- The setup waits for both Deployments to report `Progressing=False` with `kubectl wait`, with a 180 second limit each and no failure on timeout. A slow machine can start the lab a little early.
- The grader waits up to 90 seconds for the Deployment status to settle after the fix.
- `kubectl wait --for=condition=Progressing=false` depends on the condition status text matching without regard to case.
