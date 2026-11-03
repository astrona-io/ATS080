---
draft: true
exam_objectives:
  - APIs for Self-Service Platforms (CRDs)
---
# Summary

A CRD can serve several versions of one kind. Each version has its own schema and three flags: `served` offers the version at an endpoint, `storage` selects the version that the API server writes to etcd (exactly one), and `deprecated` marks a version that clients should leave. The API server converts each request to the storage version and converts responses to the requested version. With the conversion strategy `None`, it changes only `apiVersion`, so versions must stay compatible and a field must never be renamed in place. The strategy `Webhook` calls a service that you run and handles real changes of shape.

The list `status.storedVersions` records every version that may have written to etcd, and the API server never shrinks it. A platform team moves the storage version, rewrites the stored objects, and only then stops serving the old version. A `deprecationWarning` reaches every client that uses the old version as a `Warning` header, so tenants can move before the endpoint disappears.

Status is part of the contract. The common format is the list `conditions`, with `type`, `status`, `reason`, `message`, `observedGeneration` and `lastTransitionTime`. Condition names should read well when `status` is `"True"`. A reader trusts a condition only when its `observedGeneration` equals `metadata.generation`, because the status can describe an older spec. The status schema validates what a controller writes, and the status subresource lets only an identity with the `databaseclaims/status` permission write it.

RBAC grants access to custom resources by group and plural resource name, for example `platform.example` and `databaseclaims`. A subresource is a separate resource name. A namespaced Role plus a RoleBinding gives a tenant group control of its own claims and nothing else, and `kubectl auth can-i` with `--as` and `--as-group` tests the result. RBAC cannot read the content of an object. A ValidatingAdmissionPolicy with a binding can read the object, the namespace and the user, but it checks only new requests and never changes objects.

A CRD alone adds an API and no behavior. Objects are stored and validated, and nothing acts on them until a controller does.

- Exactly one version has `storage: true`.
- A Role without a RoleBinding grants nothing.
- A policy without a binding does nothing.
- Trust a condition only when `observedGeneration` is current.

<!-- astrona:playground:destroy -->
