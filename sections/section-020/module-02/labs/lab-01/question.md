# Question

Solve this question on: `terminal`

The platform team runs the `DatabaseClaim` API in the group `platform.example`. The CRD `databaseclaims.platform.example` serves two versions, `v1alpha1` and `v1beta1`, and `v1alpha1` is still the storage version. The claim `scout-db` exists in the namespace `starfleet`. Its spec changed once, so its `metadata.generation` is 2, and it has no status. The namespace `outpost` belongs to another team. There are no Roles or RoleBindings for this API. `kubectl` points at the cluster as the cluster administrator.

1. **Versions.** Make `v1beta1` the only storage version. Keep both versions served and keep the conversion strategy `None`. Mark `v1alpha1` as deprecated with a `deprecationWarning` that names `v1beta1`.

2. **Tenant access.** In the namespace `starfleet`, give the group `team-starfleet` the verbs `create`, `get`, `list`, `watch`, `update`, `patch` and `delete` on `databaseclaims`. Give the group `auditors` only `get`, `list` and `watch` on the same resource. Use a Role and a RoleBinding for each group. Do not use a wildcard, do not grant `databaseclaims/status` and do not use a ClusterRoleBinding. The group `team-outpost` must have no access in `starfleet`.

3. **Status.** Act as the platform controller. Write the status of `scout-db` through the status subresource with a `Ready` condition whose `status` is `"True"`. The condition needs a `reason`, a `message`, a `lastTransitionTime` and an `observedGeneration` that equals the current `metadata.generation` of the claim. Set `status.observedGeneration` to the same number.

Do not delete the CRD or the claim `scout-db`. Do not remove the schema or the CEL rules. Check your Roles with `kubectl auth can-i` and the flags `--as` and `--as-group`. The API server reloads a changed CRD in the background, so wait a few seconds after each change.
