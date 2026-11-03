---
draft: true
exam_objectives:
  - Kubernetes Reconciliation Loop
---
# Controllers, Desired State And The Control Loop

Kubernetes does not run commands one after another. You write down what you want, and a set of programs called controllers keeps working until the cluster matches it. This idea is the reason a deleted pod comes back, a scaled Deployment grows, and a failed node does not cause an outage. It is also the model behind every platform API that you will build on top of Kubernetes.

Keep one sentence in mind for this module: **a controller repeatedly reads the desired state in `spec`, compares it with the observed state, acts on the difference, and writes what it saw into `status`.** The module follows that sentence through the built-in Deployment controller. You will read `spec` and `status` on real objects, follow the chain of owners from a Deployment to a pod, watch the API server send changes, and see why a controller that works from the current state does not need to hear every event.

The module has three parts. **Spec, Status And The Control Loop** defines desired and observed state and walks through the four steps of one reconciliation. **Ownership From Deployment To Pod** follows `ownerReferences` through the Deployment, the ReplicaSet and the pod, and shows self-healing at each level. **Watches And Level-Triggered Reconciliation** explains how a controller learns about changes with a watch and a `resourceVersion`, and why it compares states instead of replaying events.

## Learning Goals

- Explain reconciliation as a loop of observe, compare, act and report.
- Read `spec`, `status`, `metadata.generation` and `status.observedGeneration` and say what each one means.
- Follow `ownerReferences` from a Deployment to its ReplicaSet and pods, and say which controller owns each link.
- Explain what a watch and a `resourceVersion` do, and why level-triggered logic survives missed events.
- Show self-healing by changing the cluster and reading the controller response from the API.

## Before You Start

You need basic Kubernetes knowledge: namespaces, pods, Deployments, Services, and `kubectl get`, `kubectl patch` and `kubectl apply`. You do not need to know how controllers are written.

Your playground is a single-node `kind` cluster running Kubernetes 1.35. Only the built-in controllers run in it.

| Namespace | What is in it |
| --- | --- |
| `starfleet` | Deployments `scout` and `probe` with two replicas each and a Service each, and the client Deployment `shuttle` |
| `outpost` | The client Deployment `drifter` |

`kubectl` already points at the playground cluster, as the cluster administrator. You install nothing on your own machine.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
