# Question

Solve this question on: `terminal`

The platform team runs a small operator that manages `Beacon` resources. The CRD `beacons.ops.starfleet.example` is installed. The operator is the Deployment `beacon-operator` in the namespace `beacon-system`. It runs the bash script stored in the ConfigMap `beacon-operator-script` (key `reconcile.sh`) and uses the service account `beacon-operator`. Two `Beacon` resources exist in the namespace `starfleet`: `scout` and `probe`.

The starter operator only creates one ConfigMap named `beacon-<name>` for each `Beacon`. It is not finished. Complete it without changing the CRD, the image or the Beacon resources named `scout` and `probe`:

1. Every child ConfigMap `beacon-<name>` must have an `ownerReference` that points to its `Beacon` (the real `uid`, `controller: true`), so the Kubernetes garbage collector deletes it with the `Beacon`. The ConfigMaps that already exist must be adopted, not recreated.

2. The operator must write `status` on every `Beacon` through the status subresource: `phase: Ready`, `observedGeneration` equal to `metadata.generation`, and `configMapName`. After a change of `spec.message`, `observedGeneration` must follow within a few seconds.

3. For every `Beacon` the operator must keep a registry entry, a ConfigMap named `starfleet-<name>` in the namespace `beacon-registry`. It creates the entry only when it is missing. A finalizer on the `Beacon` must make sure that the entry is deleted before the `Beacon` disappears.

4. The service account must keep least privilege: Roles per namespace, no access to Secrets, no `delete` on ConfigMaps in `starfleet`, no `delete` on `Beacon` resources. Grant only what steps 1 to 3 need.

The operator reads its script when the pod starts, so restart the Deployment after you change the ConfigMap. Restarting the operator must not recreate or duplicate any object. `kubectl` already points at the cluster.
