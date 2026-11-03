# Question

Solve this question on: `terminal`

The platform team offers developers an `Outpost` claim. A developer creates a claim in the `starfleet` namespace, and the platform must create a namespace and a `scout` Deployment for it. Crossplane, `provider-kubernetes` and `function-patch-and-transform` are installed. The XRD for the composite resource `XOutpost` and the claim `Outpost` is installed too. It has one field, `spec.replicas` (an integer from 1 to 3), and one status field, `status.namespace`. The XRD names a default Composition called `outpost-kubernetes`, but that Composition does not exist yet. A `ProviderConfig` named `local-cluster` exists, and `kubectl` already points at the cluster as the cluster administrator.

1. Create a Composition named `outpost-kubernetes` for the composite type `platform.starfleet.example/v1alpha1`, kind `XOutpost`. It must run in `Pipeline` mode and call the function `function-patch-and-transform`. It composes two `Object` resources (`kubernetes.crossplane.io/v1alpha2`, `ProviderConfig` `local-cluster`):
   - `namespace`: a Kubernetes `Namespace` named `outpost-<claim name>`. Take the claim name from the label `crossplane.io/claim-name` on the composite resource.
   - `deployment`: a Deployment named `scout` in that namespace. It runs the image `ghcr.io/stefanprodan/podinfo:6.15.0` with the container port `9898`, the label `app: scout`, and a replica count that comes from `spec.replicas` of the composite resource. Use the readiness policy `AllTrue` so the claim is Ready only when the Deployment is.

2. Copy the namespace name back to the composite resource field `status.namespace`.

3. Create an `Outpost` claim named `scout` in the namespace `starfleet` with `replicas: 2`. Wait until it is `Synced` and `Ready`.

Do not change the XRD, the function, the provider or the `ProviderConfig`.
