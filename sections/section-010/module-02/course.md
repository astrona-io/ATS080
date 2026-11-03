---
draft: true
exam_objectives:
  - Kubernetes Reconciliation Loop
---
# Convergence, Drift And Blocked Progress

A control loop is only useful when you can tell what it is doing. Most of the time the cluster converges and nobody looks. The important moments are the other ones: someone changes an object by hand, a new version never becomes ready, or a deletion never finishes. In each case the controller is still running, and the objects already contain the evidence. The skill is to read it.

Keep one sentence in mind for this module: **convergence is the state where observed equals desired, and when it does not happen, `status.conditions` and events say which step is blocked and why.** You will see drift corrected, a rollout move between ReplicaSets, conditions change as a rollout succeeds or stalls, and a deletion held by a finalizer. You will break a Deployment on purpose in three ways and read each failure from the API.

The module has four parts. **Drift Correction And Rollouts** shows how a controller undoes a manual change, how a rollout uses two ReplicaSets, and why the actions are safe to repeat. **Conditions And Progress Deadlines** reads the `Available` and `Progressing` conditions, `observedGeneration` and `progressDeadlineSeconds`. **Reading Blocked Progress** follows a Deployment that cannot converge through events, pod conditions and back-off. **Finalizers And Garbage Collection** explains how deletion works, and what holds it.

## Learning Goals

- Explain drift and show a controller correcting it.
- Describe a rolling update through the two ReplicaSets and the `maxSurge` and `maxUnavailable` settings.
- Read the `Available`, `Progressing` and `ReplicaFailure` conditions and their reasons.
- Explain `progressDeadlineSeconds` and say what the controller does and does not do when it passes.
- Diagnose a blocked rollout from events, pod status and conditions, and explain the retry back-off.
- Explain finalizers, `deletionTimestamp` and the three cascade modes of deletion.

## Before You Start

You need basic Kubernetes knowledge: Deployments, ReplicaSets, pods, `kubectl get`, `kubectl describe` and `kubectl patch`. You need to know that a controller compares `spec` with the observed state and writes `status`.

Your playground is a single-node `kind` cluster running Kubernetes 1.35. Only the built-in controllers run in it.

| Namespace | What is in it |
| --- | --- |
| `starfleet` | Deployments `scout` and `probe` with two replicas each, a Service each and `progressDeadlineSeconds: 60`, and the client Deployment `shuttle` |
| `outpost` | The client Deployment `drifter` |

`kubectl` already points at the playground cluster, as the cluster administrator. You install nothing on your own machine.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
