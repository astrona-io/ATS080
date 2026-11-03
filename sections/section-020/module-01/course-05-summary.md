---
draft: true
exam_objectives:
  - APIs for Self-Service Platforms (CRDs)
---
# Summary

A CustomResourceDefinition teaches the kube-apiserver a new kind. The CRD names the group, the plural and singular names, the kind, the scope and the versions. The API server then serves a REST endpoint, validates each request and stores accepted objects in etcd. No controller, no pod and no container run for the CRD itself. Deleting a CRD deletes every stored object of that kind, so a platform team changes a schema by applying an updated CRD.

The scope is a design decision. A tenant API is namespaced, so each team owns its claims and RBAC grants access per namespace. The scope of an existing CRD cannot change.

The `openAPIV3Schema` is the contract. Every request is checked against it before storage. A structural schema gives each node a type, and it enables two behaviors: pruning, which silently removes fields that the schema does not list, and defaulting, which writes a value for an absent field when the request arrives and when the object is read from etcd. Keywords such as `required`, `enum`, `minimum`, `maximum`, `maxLength` and `pattern` reject bad values with a 422 error that names the field. A schema change does not re-check objects that are already stored.

Rules that span several fields, or that compare the old and the new object, use CEL in `x-kubernetes-validations`. A rule sees `self`, and a transition rule also sees `oldSelf` and runs only on update. Rules run after defaulting and after the schema check. They have a cost budget, which is why strings and lists need `maxLength` and `maxItems`. A CRD rule cannot see the user, other objects or namespace labels.

Spec holds the desired state that the tenant writes. Status holds the observed state that a controller writes. The status subresource separates them: the main endpoint ignores status, and the `/status` endpoint ignores everything else. With the subresource, `metadata.generation` rises only when the spec changes, and a controller records the generation it handled in `status.observedGeneration`. Printer columns define what `kubectl get` shows, and the schema descriptions are what `kubectl explain` prints.

- The schema runs for every client, because the API server enforces it.
- Defaults apply on write and on read; pruning applies on write.
- A transition rule needs an existing object.
- The subresource is what makes it possible to grant spec and status to different identities.

<!-- astrona:playground:destroy -->
