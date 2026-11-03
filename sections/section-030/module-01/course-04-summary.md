---
draft: true
exam_objectives:
  - Infrastructure Provisioning with Kubernetes
---
# Summary

Crossplane lets a platform team add its own APIs to Kubernetes. A composite resource definition (XRD) is the contract. It names an API group, a composite kind and a claim kind, and it holds an OpenAPI schema that the Kubernetes API server enforces. One XRD generates two custom resource definitions. The composite resource is cluster-scoped and is the object that Crossplane reconciles. The claim is namespaced, has the same schema, and is the only object a developer creates. The claim stores a reference to its composite resource, and the composite resource stores the name and namespace of its claim in labels.

A Composition is the recipe for one composite kind. In pipeline mode it lists steps, and each step calls a function with an input. The function patch-and-transform reads the composite resource and returns desired composed resources. Each resource has a unique name, a base object and patches. A patch copies a field from the composite resource into the composed resource, or back into the composite status, and a transform such as a string format changes the value on the way. With the provider for Kubernetes, the composed resource is an Object that wraps a manifest, so the external resource is another Kubernetes object.

Reconciliation is done by separate controllers that each watch objects and change objects. The claim controller creates the composite resource, the composite controller runs the pipeline and creates composed resources with owner references, and the provider creates the wrapped objects. Every object reports the conditions Synced and Ready. A failure is found by reading the conditions from the claim downward until the first object that is not synced.

Key facts:

- A claim is the developer request, and a composite resource is the object that is reconciled.
- Readiness of a composed Object is only meaningful when the readiness policy matches what must be true.
- Changing the claim spec changes the composed resources, and editing a composed resource by hand is reverted.
- Deleting a claim deletes its composite resource and, by default, the composed resources and the objects they wrap.

<!-- astrona:playground:destroy -->
