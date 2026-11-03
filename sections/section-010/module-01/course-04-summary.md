---
draft: true
exam_objectives:
  - Kubernetes Reconciliation Loop
---
# Summary

Kubernetes stores desired state and observed state on the same object. The `spec` field holds what a user wants, and a controller writes the `status` field with what it found. A controller runs the same loop each time: it observes the current objects, compares them with `spec`, acts through the API server and reports the result. It keeps no memory of earlier commands, so a restart in the middle of the work loses nothing.

Two counters tell a reader whether `status` can be trusted. `metadata.generation` rises when `spec` changes, and `status.observedGeneration` shows the last generation that the controller processed. A reader that skips this comparison can take a result for an old `spec` as the result of the new one.

A Deployment does not create pods. The Deployment controller creates ReplicaSets, the ReplicaSet controller creates pods, and the kubelet runs them. Each object records its owner in `metadata.ownerReferences` with the owner `uid`, and a controller manages only the objects that it owns and that match its selector. The garbage collector removes objects whose owner is gone. This gives self-healing at the pod level and at the ReplicaSet level. It stops at an object that nothing owns: a deleted Deployment stays deleted.

Controllers learn about changes through a watch, a long-lived request that streams `ADDED`, `MODIFIED` and `DELETED` events. The `resourceVersion` marks a position in the history, and it also works as an optimistic lock: a write that carries an old version fails with a conflict, and the writer must read again. An informer keeps a local cache, and a work queue gives the reconcile function a key, not an event.

Controllers are level-triggered. They decide from the current state, so many changes in a short time collapse into one pass, a lost event is found at the next resync, and a controller that was offline catches up at start-up.

- `spec` is the request, `status` is the report, and only the controller writes `status`.
- `generation` against `observedGeneration` shows whether the report is current.
- The `uid` in `ownerReferences` makes the owner link exact.
- `resourceVersion` is an opaque value: compare it only for equality.
- A reconcile function works from the current state and must be safe to repeat.

<!-- astrona:playground:destroy -->
