# Question

Solve this question on: `terminal`

The platform team offers teams a self-service API for environments. A team writes an `Environment` object and a platform controller (not part of this lab) builds it later. Your task is to define the whole API contract. The cluster has the namespaces `starfleet` and `outpost` and nothing else. `starfleet` has the label `platform.example/prod-allowed=true` and `outpost` has no such label. `kubectl` points at the cluster as the cluster administrator.

1. **The CRD.** Create the CRD `environments.platform.example` with the kind `Environment`, the short name `env`, the scope `Namespaced` and the single version `v1alpha1`, which is served and stored.

2. **Schema and defaults.** In `spec`:
   - `tier` is required and allows only `dev`, `staging` and `prod`.
   - `owner` is required and matches the pattern `^[a-z0-9-]{3,30}$`.
   - `replicas` is an integer from 1 to 10 with the default `1`.
   - `region` allows only `eu-north` and `eu-west`, with the default `eu-north`.
   - `ttlDays` is an integer from 1 to 90 with the default `14`.

3. **Rules.** With CEL, a `prod` environment must have at least 2 replicas, and `owner` cannot change after creation.

4. **Status and columns.** Enable the status subresource. Add `status` with `phase` (string), `observedGeneration` (integer, format `int64`) and `conditions` (a list keyed by `type`, where `status` allows only `"True"`, `"False"` and `"Unknown"`). `kubectl get environments` shows the columns `Tier`, `Owner`, `Phase` and `Age`.

5. **Tenant access.** In both namespaces, the group `team-starfleet` (in `starfleet`) and the group `team-outpost` (in `outpost`) manage environments in their own namespace with `create`, `get`, `list`, `watch`, `update`, `patch` and `delete`. The group `auditors` has `get`, `list` and `watch` in both namespaces. No tenant writes status. Use Roles and RoleBindings, no wildcard and no ClusterRoleBinding.

6. **Production rule.** With a ValidatingAdmissionPolicy and a binding that uses `Deny`, allow `tier: prod` only in namespaces that have the label `platform.example/prod-allowed` set to `true`. Other tiers stay allowed everywhere.

Test with `kubectl apply --dry-run=server` and `kubectl auth can-i --as --as-group`. The API server reloads CRDs and policies in the background, so wait a few seconds after each change.
