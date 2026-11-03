# Overview: Claims, XRDs And Compositions (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Crossplane installed and then waits. There is no task, no `astrona submit` and no pass or fail. Write an API, create a claim, watch what Crossplane builds, change something, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it, as the cluster administrator. You need `jq` and `helm` on your machine.
- Crossplane 2.4.3 in the namespace `crossplane-system`.
- The provider `provider-kubernetes` v1.4.1. It turns a Crossplane `Object` into a real Kubernetes object, so no cloud account is needed.
- The function `function-patch-and-transform` v0.11.2, which runs the steps of a Composition.
- A `ProviderConfig` named `local-cluster` that tells the provider to use its own service account, which is bound to `cluster-admin`.
- The namespaces `starfleet` (for claims) and `starfleet-records`.
- No XRD, no Composition and no claim.

## Things to try

1. Check that the packages are healthy.

   ```sh
   kubectl get providers.pkg.crossplane.io,functions.pkg.crossplane.io
   ```

2. Write an XRD with the group `platform.starfleet.example`, composite kind `XOutpost` and claim kind `Outpost`. Apply it and list the new custom resource definitions.

   ```sh
   kubectl get crds | grep platform.starfleet.example
   ```

3. Write a Composition that composes a Namespace `Object` and a Deployment `Object`, and create an `Outpost` claim in `starfleet`. Then follow the chain from the claim to the composite resource to the composed Objects.

   ```sh
   kubectl -n starfleet get outposts
   kubectl get xoutposts
   kubectl get objects.kubernetes.crossplane.io
   ```

4. Change `spec.replicas` of the claim and watch the Deployment follow.
5. Delete the claim and watch every composed object disappear.
6. Add a required field to the schema and see what happens to an old claim.

## Reset

`astrona destroy ats-080-playground-030-01` removes the cluster. Run `astrona run` again for a fresh start.
