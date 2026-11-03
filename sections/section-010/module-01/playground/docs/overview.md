# Overview: Controllers, Desired State And The Control Loop (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with the example workloads and then waits. There is no task, no `astrona submit` and no pass or fail. Look at the objects, change them, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` already points at it, as the cluster administrator. Only the built-in controllers run: no operator and no extra controller is installed.

  | Namespace | What is in it |
  | --- | --- |
  | `starfleet` | Deployments `scout` (podinfo) and `probe` (go-httpbin) with two replicas each and a Service each, and the client Deployment `shuttle` (curl) |
  | `outpost` | The client Deployment `drifter` (curl) |

## Practice tasks

- Print `.spec.replicas` and `.status.readyReplicas` of `scout`, then scale it to 3 and print the same two fields again. Find the moment when the numbers differ.
- Follow the chain `scout` Deployment, ReplicaSet and Pod by printing `.metadata.ownerReferences` at each level. Write down the `uid` that each level points at.
- Run `kubectl -n starfleet get pods -w` in one terminal. In another terminal, delete a `probe` pod and read the lines that the watch prints.
- Print `.metadata.resourceVersion` of the `scout` Deployment, change one label on it, and print it again.
- Delete the ReplicaSet of `probe` by hand and see which component creates it again.
- Print `.metadata.generation` and `.status.observedGeneration` of `scout` before and after a patch.
