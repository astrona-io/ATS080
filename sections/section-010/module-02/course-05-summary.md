---
draft: true
exam_objectives:
  - Kubernetes Reconciliation Loop
---
# Summary

Convergence is the state in which the observed state equals the desired state. Drift is any difference that appears without the owner asking for it. A controller does not need the cause: it compares, and the same repair runs for a manual edit, a lost pod or a failed node. A controller owns the layer below it, so a change to a ReplicaSet is drift that the Deployment controller reverses, and a change to the Deployment is a new desired state that it follows.

A rollout is the same loop applied to a new pod template. The Deployment keeps one ReplicaSet for each template, moves replicas from the old one to the new one in steps set by `maxSurge` and `maxUnavailable`, and waits for availability before it removes old pods. A rollback writes an earlier template back into `spec.template`, and the controller reuses the matching ReplicaSet. The actions are idempotent, so repeating a pass changes nothing, and the controller records its expected creations so that a lagging cache does not cause duplicates.

Conditions report the state as a level. `Available` says whether enough replicas serve requests, and `Progressing` says whether the rollout moves forward. `ProgressDeadlineExceeded` means that no progress happened within `progressDeadlineSeconds`. The controller reports this and keeps trying. It does not roll back, and `Available` can stay `True` because the old pods keep running. Tools read `type`, `status` and `reason`, and compare `observedGeneration` with `generation` first.

When progress stops, the cause is below the Deployment. A reading order of Deployment, ReplicaSet, pod, events and logs finds it. An image that cannot be pulled shows `ErrImagePull` and `ImagePullBackOff` from the kubelet. A pod that no node can hold stays `Pending` with `Unschedulable` and a `FailedScheduling` event from the scheduler. A pod that runs and fails its readiness probe is not ready and receives no traffic. Retries use exponential back-off, so a fix can take effect late for a pod that is already waiting, and a template change gives a new pod without that history.

Deletion has two parts. A finalizer keeps an object in the API, marked with a `deletionTimestamp`, until the controller that owns it has done its cleanup and removed the entry. The garbage collector follows `ownerReferences` and removes dependents according to the cascade mode: background, foreground or orphan. A missing controller leaves an object terminating, and removing a finalizer by hand skips the cleanup behind it.

- Drift is reversed by the owner of the layer, so change the highest object that you own.
- `Progressing=False` with `ProgressDeadlineExceeded` is a report, not an action.
- Read the failure from the lowest object that shows it: pod status and events.
- Events expire and are for people, while conditions are for automation.
- A finalizer is a promise of cleanup, so remove it only after the work is done.

<!-- astrona:playground:destroy -->
