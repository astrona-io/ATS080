---
draft: true
exam_objectives:
  - APIs for Self-Service Platforms (CRDs)
---
# Printer Columns, Status And kubectl explain

A good API is easy to read from the terminal. A tenant who runs `kubectl get` wants to see the engine, the environment and whether the database is ready. A tenant who is unsure which fields exist wants documentation in the same terminal. This part adds three features that serve the reader of the API: printer columns, the status subresource with a status schema, and the schema descriptions that `kubectl explain` prints.

## Spec and status

Every Kubernetes object that a controller manages has two parts. The **spec** holds the desired state, which the tenant writes. The **status** holds the observed state, which the controller writes. The two have different owners, so they need different permissions. A tenant must be able to change `spec.storageGB` and must not be able to claim that the database is `Ready`.

Kubernetes solves this with the **status subresource**. A subresource is a separate endpoint below the main resource: `.../databaseclaims/scout-db` for the object and `.../databaseclaims/scout-db/status` for its status. When a CRD enables the subresource, the main endpoint ignores changes to `status`, and the `/status` endpoint ignores changes to everything except `status`. RBAC can then grant the two endpoints separately.

## Add printer columns, a status schema and the subresource

The change patches three places in the CRD. Save this as `crd-patch-status.yaml`:

<!-- astrona:playground:renew -->

```yaml
- op: add
  path: /spec/versions/0/subresources
  value:
    status: {}
- op: add
  path: /spec/versions/0/additionalPrinterColumns
  value:
    - name: Engine
      type: string
      jsonPath: .spec.engine
    - name: Environment
      type: string
      jsonPath: .spec.environment
    - name: Storage
      type: integer
      jsonPath: .spec.storageGB
    - name: Phase
      type: string
      jsonPath: .status.phase
    - name: Age
      type: date
      jsonPath: .metadata.creationTimestamp
- op: add
  path: /spec/versions/0/schema/openAPIV3Schema/properties/status
  value:
    type: object
    description: Observed state, written by the platform controller.
    properties:
      phase:
        type: string
        description: Summary of the lifecycle, for example Pending or Ready.
      observedGeneration:
        type: integer
        format: int64
        description: The metadata.generation that the controller last processed.
      connectionSecretName:
        type: string
        description: Name of the Secret that holds the connection details.
      conditions:
        type: array
        description: Detailed state, one entry for each condition type.
        x-kubernetes-list-type: map
        x-kubernetes-list-map-keys:
          - type
        items:
          type: object
          required:
            - type
            - status
          properties:
            type:
              type: string
              maxLength: 316
            status:
              type: string
              enum:
                - "True"
                - "False"
                - Unknown
            reason:
              type: string
              maxLength: 1024
            message:
              type: string
              maxLength: 32768
            observedGeneration:
              type: integer
              format: int64
            lastTransitionTime:
              type: string
              format: date-time
```

Apply it:

```sh
kubectl patch crd databaseclaims.platform.example --type=json --patch-file crd-patch-status.yaml
```

Wait a few seconds, then list the claims:

```sh
kubectl get dbc -n starfleet
```

The table now has the columns `NAME`, `ENGINE`, `ENVIRONMENT`, `STORAGE`, `PHASE` and `AGE`. The API server builds the table from the `jsonPath` of each column, so the data comes from the stored object, and `kubectl` needs no knowledge of the kind. The `Name` column is always first. The `PHASE` column is empty, because no status exists yet. When a CRD defines no columns, the table shows only the name and the age.

A column can also carry `priority` and `description`. A column with `priority: 1` appears only with `-o wide`. Use it for details such as a connection Secret name, and keep the default view short.

## The status subresource in practice

The tenant, or any client that uses the main endpoint, cannot write status. Try it:

```sh
kubectl patch dbc scout-db -n starfleet --type=merge -p '{"status":{"phase":"Ready"}}'
kubectl get dbc scout-db -n starfleet -o jsonpath='{.status}{"\n"}'
```

The patch reports no change, and the second command prints nothing. The API server dropped the status part of the request. Now write the same value through the subresource. The flag `--subresource=status` sends the request to the `/status` endpoint:

```sh
kubectl patch dbc scout-db -n starfleet --subresource=status --type=merge -p '{"status":{"phase":"Ready"}}'
kubectl get dbc -n starfleet
```

The patch succeeds, and the `PHASE` column of `scout-db` shows `Ready`. In a real platform, the controller of the claim sends this request with its own credentials. Here you act as the cluster administrator, which stands in for the controller. The point is the separation: a tenant role that lacks the `databaseclaims/status` permission cannot do this.

## The generation counter

The subresource also changes how the counter `metadata.generation` works. The API server raises `generation` by one on each change of the spec, and does not raise it on a change of the status or of the metadata. Read it before and after the status patch:

```sh
kubectl get dbc scout-db -n starfleet -o jsonpath='{.metadata.generation}{"\n"}'
kubectl patch dbc scout-db -n starfleet --type=merge -p '{"spec":{"storageGB":40}}'
kubectl get dbc scout-db -n starfleet -o jsonpath='{.metadata.generation}{"\n"}'
```

The second reading is one higher than the first, because the spec changed. A controller copies `generation` into `status.observedGeneration` when it finishes a pass. A reader who sees both numbers equal knows the status describes the current spec. The next module builds on this.

## Read the contract with kubectl explain

The command `kubectl explain` reads the schema from the API server and prints the field descriptions. It works for custom resources because the CRD publishes its schema in the cluster OpenAPI document. Try the top level and then one field:

```sh
kubectl explain databaseclaim.spec
kubectl explain databaseclaim.spec.storageGB
```

The first command lists the fields of `spec` with their types and descriptions, and marks `engine` as required. The second prints the description, the type and the default text if you wrote one in the description. The flag `--recursive` prints the whole tree, and `--api-version=platform.example/v1alpha1` selects a version when the CRD serves several. A tenant can learn the contract without reading the CRD file.

The descriptions you wrote in the schema are the only source. The CEL rules do not appear in the output, so write the rule in plain words in the `description` of the field when it matters to the tenant, for example "Cannot be changed after creation".

## Field selectors

A CRD can also mark fields that clients may filter on. The list `selectableFields` in a version holds entries such as `jsonPath: .spec.engine`. With it, `kubectl get dbc --field-selector spec.engine=postgres` filters on the server. Without it, only `metadata.name` and `metadata.namespace` are selectable. This feature is stable from Kubernetes 1.32. Use it for the one or two fields that clients filter on often.

This part made the API readable and gave it a separate place for observed state. The tenant contract is now complete for a single version: a schema with defaults and limits, CEL rules, columns, a status subresource and field documentation. The open question is how the API changes over time without breaking tenants, and who may use it.

## Common pitfalls

> [!WARNING]
> - **Defining status in the schema without the subresource.** Then every client can write `status`, and a tenant can set `Ready` by hand.
> - **Enabling the subresource and forgetting RBAC.** The `databaseclaims/status` endpoint needs its own rule. Grant it only to the controller.
> - **Expecting `kubectl apply` to set status.** Apply goes to the main endpoint, which ignores `status` when the subresource is on.
> - **Too many printer columns.** Wide tables wrap and become unreadable. Use `priority: 1` for details.
> - **Hiding rules from `explain`.** CEL rules are not printed, so put the tenant-facing meaning in `description`.
