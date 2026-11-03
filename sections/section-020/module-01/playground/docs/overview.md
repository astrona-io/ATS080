# Overview: CRD Schemas And Validation (Playground)

This is a **playground**, not a lab. It starts a fresh cluster and waits. There is no task, no `astrona submit` and no pass or fail. Write CRDs, break them, run `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` already points at it, as the cluster administrator. No controller, webhook or policy engine runs in it.

  | Namespace | What is in it |
  | --- | --- |
  | `starfleet` | Empty. Tenant namespace for the first team. |
  | `outpost` | Empty. Tenant namespace for the second team. |

- No CustomResourceDefinition. The first reading step applies one for the kind `DatabaseClaim` in the group `platform.example`.

## Useful commands

```sh
kubectl api-resources --api-group=platform.example
kubectl get crd databaseclaims.platform.example -o yaml
kubectl apply --dry-run=server -f <file>
kubectl explain databaseclaim.spec
```

A server-side dry run sends a request through the whole API server pipeline and stores nothing. It is the safest way to test a schema.

## Practice tasks

- Add a field `region` with the allowed values `eu-north` and `eu-west` and a default. Apply a claim without it and read the stored value.
- Add a rule that a `mysql` claim must set `version`. Use `has(self.version)`.
- Make `storageGB` unchangeable with a transition rule and test it with `kubectl patch`.
- Add the printer column `Version` and check `kubectl get dbc -o wide` with `priority: 1`.
- Apply a claim with a field the schema does not know and compare `--validate=strict` with `--validate=ignore`.
