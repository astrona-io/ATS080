---
draft: true
exam_objectives:
  - APIs for Self-Service Platforms (CRDs)
---
# Status Conditions As A Contract

A tenant who applies a `DatabaseClaim` asks a question that the spec cannot answer: is my database ready? The answer lives in the status. If every platform component writes status in its own style, tenants and pipelines cannot depend on it. This part defines the shape of a status condition, shows who may write it, and explains why the field `observedGeneration` makes it trustworthy.

## Status is a promise to the reader

The spec is the request. The status is the report that a controller writes back. A tenant, a continuous delivery tool or another controller reads the status and decides what to do next: wait, alert or continue. When the format of the status changes without notice, every one of these readers breaks. That is why the status is part of the API contract, in the same way as the spec.

Kubernetes has a common format for the detailed part of a status: the list `conditions`. A **condition** is one named fact about the object, and it has these fields:

| Field | Meaning |
| --- | --- |
| `type` | The name of the fact, in CamelCase, such as `Ready`. Each type appears once in the list. |
| `status` | `"True"`, `"False"` or `"Unknown"`. The values are strings. `Unknown` means the controller cannot tell. |
| `reason` | A short CamelCase cause, such as `Provisioning`. A program can switch on it. |
| `message` | A sentence for a person. |
| `observedGeneration` | The `metadata.generation` of the object when the controller set this condition. |
| `lastTransitionTime` | The time when `status` last changed from one value to another. |

The schema from the earlier module already defines this list. It marks `type` and `status` as required, limits `status` to the three values with `enum`, and uses `x-kubernetes-list-type: map` with `x-kubernetes-list-map-keys: [type]`. The last two keywords tell the API server that the list behaves like a map keyed by `type`, so two controllers can update different condition types without replacing each other's entries when they use server-side apply.

## Write a condition

No controller runs in the playground, so you act as one. The claim `scout-db` exists and has `metadata.generation` 1, because its spec has not changed since creation. Check it:

<!-- astrona:playground:renew -->

```sh
kubectl get dbc scout-db -n starfleet -o jsonpath='{.metadata.generation}{"\n"}'
```

The command prints `1`. Save this status as `status-scout-db-provisioning.yaml`:

```yaml
status:
  phase: Provisioning
  observedGeneration: 1
  conditions:
    - type: Ready
      status: "False"
      reason: Provisioning
      message: The database is being created.
      lastTransitionTime: "2026-11-03T10:00:00Z"
```

A controller writes through the status subresource, so send it there:

```sh
kubectl patch dbc scout-db -n starfleet --subresource=status --type=merge --patch-file status-scout-db-provisioning.yaml
kubectl get dbc scout-db -n starfleet
```

The `PHASE` column shows `Provisioning`. A JSON merge patch replaces a whole list, so this request sets the complete `conditions` list. A real controller that owns several condition types uses server-side apply, which merges the list by `type`.

Now report success. Save this as `status-scout-db-ready.yaml`:

```yaml
status:
  phase: Ready
  observedGeneration: 1
  connectionSecretName: scout-db-conn
  conditions:
    - type: Ready
      status: "True"
      reason: Provisioned
      message: The database accepts connections.
      observedGeneration: 1
      lastTransitionTime: "2026-11-03T10:05:00Z"
```

Apply it to the subresource and wait on the condition:

```sh
kubectl patch dbc scout-db -n starfleet --subresource=status --type=merge --patch-file status-scout-db-ready.yaml
kubectl wait --for=condition=Ready dbc/scout-db -n starfleet --timeout=30s
```

The `kubectl wait` command reads `status.conditions`, finds the entry of type `Ready` and returns when its `status` is `"True"`. A pipeline uses this single command to hold a deployment until the database exists. That works only because every claim reports `Ready` in the same way. This is the benefit of a condition contract.

## observedGeneration shows whether the status is current

The status can be old. Change the spec and read the two numbers:

```sh
kubectl patch dbc scout-db -n starfleet --type=merge -p '{"spec":{"storageGB":50}}'
kubectl get dbc scout-db -n starfleet -o jsonpath='generation={.metadata.generation} observed={.status.observedGeneration}{"\n"}'
```

The output shows `generation=2 observed=1`. The `Ready` condition still says `"True"`, but it describes the claim as it was at generation 1. The new size of 50 gibibytes has not been processed. A reader that checks only `status` would believe the volume is ready at the new size. A careful reader compares `observedGeneration` with `metadata.generation` and treats a lower number as "not yet processed".

The controller closes the gap when it finishes its work and writes `observedGeneration: 2`. Write that to confirm the rule:

```sh
kubectl patch dbc scout-db -n starfleet --subresource=status --type=merge -p '{"status":{"observedGeneration":2,"conditions":[{"type":"Ready","status":"True","reason":"Provisioned","message":"The database accepts connections.","observedGeneration":2,"lastTransitionTime":"2026-11-03T10:10:00Z"}]}}'
kubectl get dbc scout-db -n starfleet -o jsonpath='generation={.metadata.generation} observed={.status.observedGeneration}{"\n"}'
```

The two numbers are now equal. The rule for readers is: trust a condition only when its `observedGeneration` equals the current `metadata.generation`.

## The schema protects the contract

The API server validates status writes against the status schema, in the same way as spec writes. Try a value outside the allowed set:

```sh
kubectl patch dbc scout-db -n starfleet --subresource=status --type=merge -p '{"status":{"conditions":[{"type":"Ready","status":"Maybe"}]}}'
```

The API server rejects the request, because `status` must be `"True"`, `"False"` or `"Unknown"`. The error names the path `status.conditions[0].status`. A controller that writes a wrong value is stopped by the schema, not by a reader in production.

## Conventions that keep conditions useful

A few habits make conditions reliable for readers.

- Name conditions so that `"True"` is good: `Ready`, `Available`, `Synced`. A condition named `Failed` makes `"True"` mean bad news, and tools that wait for `"True"` get confused.
- Set `reason` on every condition, in CamelCase, from a fixed list that you document. Programs match on `reason`; people read `message`.
- Change `lastTransitionTime` only when `status` changes. A value that updates on every pass hides the real time of the last change.
- Keep a short `phase` only for display. A phase is a single value that hides combinations of facts, so decisions should use conditions.
- Add condition types for separate facts, such as `Ready` for connections and `BackupConfigured` for backups, instead of putting everything into one message.

This part gave the status a fixed shape, wrote it through the subresource and used `observedGeneration` to detect a stale report. The status is only trustworthy if the right identity writes it. The next part decides who may write what.

## Common pitfalls

> [!WARNING]
> - **Trusting `Ready` without `observedGeneration`.** The condition can describe an older spec.
> - **Writing status through the main endpoint.** It is ignored when the status subresource is on. Use the `/status` endpoint.
> - **Replacing the list with a merge patch.** A JSON merge patch overwrites every condition. Use server-side apply for lists that several writers share.
> - **Inverted condition names.** A condition where `"True"` is bad breaks `kubectl wait` and generic tools.
> - **Moving `lastTransitionTime` on every update.** The time then says nothing about when the state changed.
