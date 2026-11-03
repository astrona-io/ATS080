# Overview: Versions, Status Contracts And Tenant Access (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with the `DatabaseClaim` CRD already applied, and waits. There is no task, no `astrona submit` and no pass or fail. Change versions, write status, grant access, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` already points at it, as the cluster administrator. No controller, webhook or policy engine runs in it.

  | Object | What it is |
  | --- | --- |
  | Namespace `starfleet` | Labeled `platform.example/prod-allowed=true` |
  | Namespace `outpost` | No label |
  | CRD `databaseclaims.platform.example` | Versions `v1alpha1` (served, storage) and `v1beta1` (served), the same schema with defaults, CEL rules and the status subresource, conversion strategy `None` |

- No claims, no Roles, no RoleBindings and no ValidatingAdmissionPolicy.

## Useful commands

```sh
kubectl get crd databaseclaims.platform.example -o jsonpath='{.status.storedVersions}{"\n"}'
kubectl get databaseclaims.v1beta1.platform.example -A
kubectl auth can-i create databaseclaims.platform.example -n starfleet --as=jean-luc --as-group=team-starfleet
```

## Practice tasks

- Create a claim through `v1alpha1`, read it through `v1beta1`, and compare `apiVersion`.
- Make `v1beta1` the storage version and read `status.storedVersions`.
- Write a `Ready` condition through the status subresource, change the spec, and compare `generation` with `observedGeneration`.
- Give a group read-only access and check that `delete` answers `no`.
- Add a ValidatingAdmissionPolicy with a binding and test it with `--dry-run=server`.
