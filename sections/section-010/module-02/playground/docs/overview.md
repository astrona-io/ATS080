# Overview: Convergence, Drift And Blocked Progress (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with the example workloads and then waits. There is no task, no `astrona submit` and no pass or fail. Break things on purpose, read the conditions and events, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` already points at it, as the cluster administrator. Only the built-in controllers run.

  | Namespace | What is in it |
  | --- | --- |
  | `starfleet` | Deployments `scout` (podinfo) and `probe` (go-httpbin) with two replicas each, a Service each and `progressDeadlineSeconds: 60`, and the client Deployment `shuttle` (curl) |
  | `outpost` | The client Deployment `drifter` (curl) |

## Practice tasks

- Set the image of `probe` to a tag that does not exist, wait about a minute and read the `Progressing` and `Available` conditions. Then set the image back and read them again.
- Raise the CPU request of `scout` to a value that no node can offer. Read the pod condition `PodScheduled` and the event that the scheduler wrote.
- Scale a ReplicaSet of `probe` by hand and watch the Deployment controller scale it back.
- Run `kubectl -n starfleet rollout history deployment/probe` after two image changes and compare the revisions.
- Create a ConfigMap with a finalizer, delete it, read `.metadata.deletionTimestamp`, and remove the finalizer.
- Delete a Deployment with `--cascade=orphan` and list the ReplicaSet that stays behind. Look at its `ownerReferences`.
