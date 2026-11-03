---
draft: true
exam_objectives:
  - Infrastructure Provisioning with Kubernetes
---
# Summary

A provider is a package that adds custom resource definitions and a controller for one target system. With provider-kubernetes the target is a Kubernetes cluster and the kind that wraps a manifest is called Object. A ProviderConfig chooses how the provider reaches the target. The source InjectedIdentity makes the provider use the token of its own service account. The ProviderConfig grants nothing: what the identity may do is decided by role-based access control, and the least privilege rule applies. A missing permission shows up on the composed Object as a failed sync whose message contains the word forbidden.

A connection detail passes through four settings. The composed Object reads a field and writes a secret, the Composition passes the key to the composite resource, the XRD lists the keys that may be published, and the claim names the secret to create in its own namespace. If any one of them is missing, the claim secret is empty or absent. Every object reports Synced and Ready. Synced is about the last reconcile and Ready is about the state of the resource, and they are independent.

Crossplane creates every composed resource it can, so one failure leaves a claim partly working and not ready. The operator reads down from the claim to the first object that is not synced. Fixing the cause fixes the claim without recreating anything.

Deletion follows owner references and the deletion policy of each Object. The default policy removes the wrapped object, and the policy Orphan leaves it behind. Management policies limit which actions a provider may take, and the policy that only observes never changes the resource. A claim delete policy decides whether the claim waits for its composed resources to be removed.

Key facts:

- A ProviderConfig picks an identity, and RBAC decides what the identity may do.
- A claim publishes a connection secret only when it names one.
- A claim can be not ready while most of its resources work.
- Orphan keeps the real resource and removes the Crossplane object.

<!-- astrona:playground:destroy -->
