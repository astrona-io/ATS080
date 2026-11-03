# Question

Solve this question on: `terminal`

The platform team must offer developers a self-service API for a small "depot": a namespace, a `scout` Deployment, and a record that survives when the depot is deleted. Build the complete claim API on this cluster. Crossplane 2.4.3, `provider-kubernetes` (bound to `cluster-admin`), `function-patch-and-transform` and a `ProviderConfig` named `local-cluster` are installed. The namespaces `starfleet` and `starfleet-records` exist. `kubectl` points at the cluster as the cluster administrator. Nothing else exists.

1. Write a `CompositeResourceDefinition` named `xdepots.platform.starfleet.example`. Group `platform.starfleet.example`, composite kind `XDepot` (plural `xdepots`), claim kind `Depot` (plural `depots`), version `v1alpha1`. The spec has one field, `replicas`: an integer with a minimum of 1, a maximum of 3 and a default of 1. The XRD publishes the connection secret key `endpoint` and names `depot-kubernetes` as its default Composition. Wait until it is `Established`.

2. Write a Composition named `depot-kubernetes` for `XDepot`, in `Pipeline` mode with `function-patch-and-transform`. All composed resources are `kubernetes.crossplane.io/v1alpha2` `Object` resources that use the `ProviderConfig` `local-cluster`. For a claim named `<name>` it composes:
   - a Namespace `depot-<name>`
   - a Deployment `scout` in that namespace with the image `ghcr.io/stefanprodan/podinfo:6.15.0`, the label `app: scout`, the container port `9898`, and the replica count from `spec.replicas`. The claim must not become Ready before the Deployment is available.
   - a ConfigMap `record-<name>` in the namespace `starfleet-records` with the data keys `claim` (the claim name) and `endpoint` (the text `scout.depot-<name>.svc.cluster.local:9898`). The Object that holds it must not delete the ConfigMap when the Object is deleted. The key `endpoint` is also the source of the connection secret key `endpoint`.

   Take `<name>` from the label `crossplane.io/claim-name` of the composite resource. The connection secret of the composite resource goes to the namespace `crossplane-system`.

3. Create the claim `scout-depot` in `starfleet` with `replicas: 2`. It writes its connection secret to a secret named `depot-conn`. Create the claim `probe-depot` in `starfleet` with `replicas: 1`. Wait until both are `Ready`.

4. Delete the claim `probe-depot` once it carries the orphan setting on its record Object. Its namespace must disappear and its record ConfigMap must stay.

5. Make sure the API rejects a `Depot` with `replicas: 5`.

Use only the objects named above. Do not delete `scout-depot`.
