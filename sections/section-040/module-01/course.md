---
draft: true
exam_objectives:
  - Kubernetes Operator Pattern for Integration
---
# The Operator Pattern: CRD Plus Controller

An operator is a controller that manages one kind of custom resource. The custom resource is the API: the user writes what they want. The controller is the code: it reads the request and changes the cluster until it matches. This module builds a small operator from nothing, so you see every piece that a real operator also has.

Keep one idea in mind: **a CustomResourceDefinition (CRD) adds a type to the API server, and only a running controller gives that type any behavior.**

The module has three parts. **A CRD Without A Controller** registers the `Beacon` type and shows that the API server stores a `Beacon` and does nothing else. **A Reconcile Loop In A Deployment** runs a bash script as the controller, with its own service account and least-privilege Roles, and makes it create a child object and write status. **Finalizers And Owner References** adds cleanup: the garbage collector removes the child, and a finalizer removes a registry entry in another namespace.

## Learning goals

After this module you can:

- Explain which part of an operator is the API (the CRD) and which part is the implementation (the controller).
- Write a CRD with a schema, a default value, a status subresource and printer columns.
- Run a controller as a Deployment with a service account and Roles that grant only what it needs.
- Write a reconcile loop that is idempotent: it creates what is missing, changes what differs and leaves the rest alone.
- Report progress with status and `observedGeneration`.
- Use `ownerReferences` and a finalizer to clean up, and explain what happens when the controller is down.

## Before you start

You need to know what a pod, a Deployment, a ConfigMap, a Role and a RoleBinding are, and how to apply a YAML file with `kubectl`. Terms are defined where they first appear.

Your playground is a single-node `kind` cluster running Kubernetes 1.35. It has these parts:

| Where | What it is |
| --- | --- |
| namespace `starfleet` | Empty. The `Beacon` resources will live here. |
| namespace `beacon-system` | Empty. The operator will run here. |
| namespace `beacon-registry` | Empty. The operator will keep one registry entry per `Beacon` here. |
| image `alpine/k8s:1.35.8` | Loaded into the node. It has `bash`, `kubectl` and `jq`. |

There is no CRD and no operator yet. `kubectl` already points at the cluster.

Launch your playground now and keep it running while you read:

<!-- astrona:playground -->
