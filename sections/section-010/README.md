---
draft: true
exam_objectives:
- Kubernetes Reconciliation Loop
---
# Kubernetes Reconciliation Loop

Kubernetes does not run commands that you give it once. You write down what you want, and controllers (programs that watch objects) keep working until the cluster matches it. This section teaches that loop from two sides. The first module explains how a controller observes, compares, acts and reports, and how a Deployment, its ReplicaSet and its pods are linked by ownership. The second module explains what happens when the loop cannot finish: drift, rollouts, conditions, progress deadlines, events, finalizers and garbage collection.

Read the module landing pages, the parts and the summaries in order. Each module has a playground for the hands-on steps in the parts and a graded lab after the last part. The capstone lab at the end combines both modules on one broken release. The quiz is indexed separately in the course manifest and comes after the capstone.

## Learning Outcomes

- Explain a controller as a loop that observes the live state, compares it with `spec`, acts, and reports in `status`.
- Read `metadata.generation` and `status.observedGeneration` to tell whether a controller has seen the latest change.
- Follow `ownerReferences` from a Pod to a ReplicaSet to a Deployment and explain what the garbage collector removes.
- Explain why level-triggered logic survives missed events and why a watch with a `resourceVersion` keeps controllers current.
- Predict how a controller corrects drift and how a rollout moves between ReplicaSets.
- Read the `Available` and `Progressing` conditions and the `progressDeadlineSeconds` setting to recognize blocked progress.
- Use events and pod status to find why a Deployment cannot converge, and fix it in place.
- Explain finalizers and `deletionTimestamp`, and release a deletion that a finalizer holds.
