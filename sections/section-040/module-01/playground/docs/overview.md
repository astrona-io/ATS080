# Overview: The Operator Pattern: CRD Plus Controller (Playground)

This is a **playground**, not a lab. It starts a fresh cluster and waits. There is no task, no `astrona submit` and no pass or fail. Write a CRD, build an operator, break it, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it.
- Three empty namespaces: `starfleet` (where `Beacon` resources will live), `beacon-system` (where the operator will run) and `beacon-registry` (where the operator will keep one registry entry per `Beacon`).
- The image `alpine/k8s:1.35.8` is loaded into the node. It contains `bash`, `kubectl` and `jq`, which is all the example operator needs.
- No CRD, no operator, no RBAC. You create them in the course steps.

## Useful commands

```sh
kubectl api-resources --api-group=ops.starfleet.example
kubectl -n beacon-system logs deployment/beacon-operator
kubectl -n starfleet get beacons,configmaps
kubectl auth can-i delete configmaps -n starfleet --as=system:serviceaccount:beacon-system:beacon-operator
```

## Practice tasks

- Create a `Beacon` with an empty `message` and read the error from the API server. Then create it with `channel: loud` and read that error.
- Change the `message` of a `Beacon` and watch `status.observedGeneration` follow `metadata.generation`.
- Delete the child ConfigMap by hand and measure how long the operator needs to recreate it.
- Scale the operator to zero replicas, delete a `Beacon` and read its `metadata.deletionTimestamp` and `metadata.finalizers`.
- Remove a verb from the Role, restart the operator and find the `Forbidden` message in its log.
