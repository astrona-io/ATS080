# Question

Solve this question on: `terminal`

The `starfleet` and `outpost` teams will request databases with a `DatabaseClaim` object in the group `platform.example`. The CRD `databaseclaims.platform.example` already exists, but it accepts any `spec`, has no status and prints only a name and an age. The claim `probe-db` in the namespace `starfleet` already exists. `kubectl` points at the cluster as the cluster administrator. Change the CRD in place so that it becomes a real API contract.

1. **Schema.** In version `v1alpha1`, make these changes to the schema:
   - `spec` is required.
   - `spec.engine` is required and allows only `postgres` and `mysql`.
   - `spec.version` is an optional string of at most 16 characters.
   - `spec.storageGB` is an integer from 1 to 500 with the default `10`.
   - `spec.environment` allows only `dev`, `staging` and `prod`, with the default `dev`.
   - `spec.highAvailability` is a boolean with the default `false`.

2. **Rules.** Add CEL validation rules with `x-kubernetes-validations`:
   - A claim with `environment: prod` must have `highAvailability: true`.
   - `spec.engine` cannot change after the claim is created.
   - `spec.storageGB` can grow but cannot shrink.

3. **Status.** Enable the status subresource. Add a `status` object to the schema with `phase` (string) and `observedGeneration` (integer, format `int64`).

4. **Printer columns.** `kubectl get databaseclaims` must show the columns `Engine` (from `.spec.engine`), `Environment` (from `.spec.environment`) and `Phase` (from `.status.phase`).

Do not delete the CRD or the claim `probe-db`. Keep the single version `v1alpha1` and the scope `Namespaced`. Test your changes with `kubectl apply --dry-run=server` before you rely on them. The API server reloads a changed schema in the background, so wait a few seconds after each change.
