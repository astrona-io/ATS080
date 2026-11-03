# Overview: Providers, Identities, Connection Secrets And Deletion (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a working `Outpost` claim API and two claims that are only partly working. There is no task, no `astrona submit` and no pass or fail. Read conditions, fix the identity, read secrets, change deletion behavior, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it, as the cluster administrator. You need `jq` and `helm` on your machine.
- Crossplane 2.4.3, provider-kubernetes v1.4.1 and function-patch-and-transform v0.11.2.
- A `ProviderConfig` named `local-cluster`. The provider service account `provider-kubernetes` is bound to a limited ClusterRole that covers namespaces, ConfigMaps and Services but not Deployments, on purpose.
- The XRD `xoutposts.platform.starfleet.example` (claim kind `Outpost`) with the connection secret key `endpoint`.
- The Composition `outpost-kubernetes` with four composed Objects: a namespace, a Service, a Deployment and a record ConfigMap in `starfleet-records`.
- Two claims in `starfleet`: `scout` and `probe`. Their Deployment Objects fail with a permission error.

## Things to try

1. Read the conditions of a claim and of each composed Object.

   ```sh
   kubectl -n starfleet get outposts
   kubectl get objects.kubernetes.crossplane.io
   ```

2. Find the message of the failing Object.

   ```sh
   kubectl get objects.kubernetes.crossplane.io -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.conditions[?(@.type=="Synced")].message}{"\n"}{end}'
   ```

3. Grant only Deployments with a new ClusterRole and watch the claim become ready.
4. Ask a claim for a connection secret with `spec.writeConnectionSecretToRef` and decode it.
5. Set `deletionPolicy: Orphan` on one composed Object in the Composition, delete a claim and see what stays.
6. Pause one composed Object with the annotation `crossplane.io/paused: "true"` and see what changes in its conditions.

## Reset

`astrona destroy ats-080-playground-030-02` removes the cluster. Run `astrona run` again for a fresh start.
