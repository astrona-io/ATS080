---
draft: true
exam_objectives:
  - Kubernetes Operator Pattern for Integration
---
# Summary

An operator has two separate parts. The CustomResourceDefinition adds a new type to the API server. The API server validates each object against the schema, fills in defaults and stores it, and it does nothing more. The controller is a normal workload, here a Deployment, that watches the type and changes the cluster to match. A cluster with the CRD and no controller accepts requests that nobody fulfils.

The controller reconciles: it compares the desired state in `spec` with the actual state and closes the difference. It must be idempotent, because it restarts, misses events and sees the same object many times. Two methods give that property. Applying the same manifest changes nothing when the object already matches. Creating only when the object is missing suits objects that never change. A level-based loop also repairs damage, such as a ConfigMap deleted by hand, without any event.

The controller reports through status. `status.observedGeneration` shows the `metadata.generation` that the controller has handled, so a reader can tell whether the status describes the current `spec`. Status goes through its own subresource and its own RBAC resource, which keeps a user from writing it by accident.

Permissions define the operator's authority. The service account gets Roles per namespace with only the verbs that the script uses. The `beacons` resource and the `beacons/status` resource are different entries in a Role. The operator needs no delete permission on its children when the garbage collector removes them.

Cleanup uses two mechanisms. An owner reference makes the garbage collector delete a child in the same namespace when the owner goes away. A finalizer holds an object in a terminating state until the controller has removed what lives outside the owner's reach, such as an entry in another namespace. If the controller is down, the object waits, and it finishes when the controller returns.

The key facts to remember are these:

- A CRD is an API. A controller is an implementation of it.
- Reconcile functions must be safe to repeat.
- A missing RBAC rule shows up as `Forbidden` in the controller log, not as a failed apply.
- The garbage collector follows owner references. Finalizers need a running controller.

<!-- astrona:playground:destroy -->
