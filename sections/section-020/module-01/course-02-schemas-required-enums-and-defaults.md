---
draft: true
exam_objectives:
  - APIs for Self-Service Platforms (CRDs)
---
# Schemas, Required Fields, Enumerations And Defaults

An open CRD stores whatever a tenant sends. A platform team needs the opposite: a contract that says which fields exist, which values are allowed and what the platform assumes when a tenant leaves a field out. This part writes that contract as an OpenAPI v3 schema inside the CRD, and shows what the API server does with each keyword.

## The schema is the contract

The field `openAPIV3Schema` holds a schema written in a subset of OpenAPI version 3, which is a standard way to describe the shape of JSON data. The API server evaluates it on every create and update request for the custom resource. A request that breaks the schema gets an HTTP 422 response, and nothing is stored.

The component that does this is the kube-apiserver, before the object reaches etcd. A controller or an admission webhook is not involved. That makes the schema the cheapest and most reliable place for a platform rule: it runs for every client, including `kubectl`, a CI pipeline and a web portal.

## Structural schemas

Kubernetes requires a **structural schema**. A schema is structural when every node has a `type`, and the nodes `properties` and `items` describe the children. Two exceptions exist: a node can use `x-kubernetes-int-or-string: true` or `x-kubernetes-preserve-unknown-fields: true` instead of a plain type. Inside `metadata`, only `name` and `generateName` can carry constraints.

A structural schema is what makes **pruning** and **defaulting** possible, because the API server must know the type of every field to drop or fill it. The open CRD from the first part is structural, because `spec` has the type `object` and uses `x-kubernetes-preserve-unknown-fields`. A schema that is not structural is rejected, and the CRD condition `NonStructuralSchema` explains why.

## The keywords you will use most

The keywords below cover most platform APIs.

| Keyword | Effect |
| --- | --- |
| `type` | `object`, `array`, `string`, `integer`, `number` or `boolean`. A value of another type is rejected. |
| `required` | A list of field names that must be present. It sits on the object that owns the fields. |
| `enum` | The value must equal one of the listed values. |
| `minimum`, `maximum` | Limits for numbers. |
| `minLength`, `maxLength`, `pattern` | Limits for strings. `pattern` is a regular expression. |
| `default` | The value the API server writes when the field is absent. |
| `description` | Text that `kubectl explain` prints. |

Write a `description` for every field. It is the documentation that tenants read in their terminal, and the next part shows how.

## Replace the open schema

Save this as `crd-databaseclaim-schema.yaml`. It keeps the name, the group and the scope, and replaces `spec` with a real contract. Only `engine` is required. The fields `storageGB`, `environment` and `highAvailability` have defaults.

<!-- astrona:playground:renew -->

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: databaseclaims.platform.example
spec:
  group: platform.example
  scope: Namespaced
  names:
    kind: DatabaseClaim
    listKind: DatabaseClaimList
    plural: databaseclaims
    singular: databaseclaim
    shortNames:
      - dbc
  versions:
    - name: v1alpha1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          required:
            - spec
          properties:
            spec:
              type: object
              description: The database a team asks for.
              required:
                - engine
              properties:
                engine:
                  type: string
                  description: Database engine. The platform offers postgres and mysql.
                  enum:
                    - postgres
                    - mysql
                version:
                  type: string
                  description: Major version of the engine, for example "16".
                  maxLength: 16
                storageGB:
                  type: integer
                  description: Size of the volume in gibibytes.
                  minimum: 1
                  maximum: 500
                  default: 10
                environment:
                  type: string
                  description: Where the database runs.
                  enum:
                    - dev
                    - staging
                    - prod
                  default: dev
                highAvailability:
                  type: boolean
                  description: Run a standby replica.
                  default: false
```

Apply it:

```sh
kubectl apply -f crd-databaseclaim-schema.yaml
```

The API server updates the endpoint in place and keeps the two claims from the first part. Wait a few seconds for the new schema to take effect, because the API server reloads it in the background.

## Required fields and enumerations in action

Save a claim that breaks two rules as `databaseclaim-probe-db-bad.yaml`:

```yaml
apiVersion: platform.example/v1alpha1
kind: DatabaseClaim
metadata:
  name: probe-db
  namespace: starfleet
spec:
  engine: oracle
  storageGB: 0
```

Check it with a server-side dry run. The flag `--dry-run=server` sends the request through the full API server pipeline, including the schema check, and does not store anything:

```sh
kubectl apply --dry-run=server -f databaseclaim-probe-db-bad.yaml
```

The API server rejects the request. The error lists every field that failed and names the field path, `spec.engine` and `spec.storageGB`, the value you sent and the allowed values or limit. The old claim `drifter-db` has the same two problems, and it still exists. The schema runs on writes, so `kubectl get dbc -A` still returns it. To clean it up, delete it with `kubectl delete dbc drifter-db -n outpost`.

## Defaults

A claim that sets only the required field shows the defaults. Save this as `databaseclaim-probe-db.yaml`:

```yaml
apiVersion: platform.example/v1alpha1
kind: DatabaseClaim
metadata:
  name: probe-db
  namespace: starfleet
spec:
  engine: mysql
```

Apply it and print the stored values:

```sh
kubectl apply -f databaseclaim-probe-db.yaml
kubectl get dbc probe-db -n starfleet -o jsonpath='{.spec.storageGB} {.spec.environment} {.spec.highAvailability}{"\n"}'
```

The command prints `10 dev false`. The API server wrote these three values; the tenant did not send them. The server applies defaults when it receives a request, and also when it reads an object from etcd. This second rule means a new default reaches objects that were stored before the default existed. The existing `scout-db` has `storageGB: 20` and gets `dev` and `false` for the other two fields when you read it.

A default applies only when its parent object exists. A default inside `spec` does nothing when the claim has no `spec` at all. That is why the schema makes `spec` required. Otherwise you would give `spec` the default `{}`.

## Pruning removes unknown fields

**Pruning** is the removal of fields that the schema does not list. It protects the platform from a typo and from a field that a later controller might read by accident. Save this as `databaseclaim-probe-db-extra.yaml`:

```yaml
apiVersion: platform.example/v1alpha1
kind: DatabaseClaim
metadata:
  name: probe-db
  namespace: starfleet
spec:
  engine: mysql
  colour: blue
```

By default `kubectl` asks the server to check fields strictly, and rejects `colour` with an unknown field error. Newer `kubectl` versions (1.27 or later) let you turn that off with `--validate=ignore`, which shows what the API server does on its own:

```sh
kubectl apply --validate=ignore -f databaseclaim-probe-db-extra.yaml
kubectl get dbc probe-db -n starfleet -o jsonpath='{.spec}{"\n"}'
```

The stored `spec` has no `colour`. The API server pruned it silently. Pruning is the default for every `apiextensions.k8s.io/v1` CRD. Only `x-kubernetes-preserve-unknown-fields: true` on a node turns it off for that node, which is what the open schema from the first part used.

## Choosing a design

A good contract names the choices a tenant must make and hides the ones the platform owns. `engine` has no default, because a wrong guess costs data. `storageGB` has a default of 10 and a limit of 500, so a tenant cannot ask for an unlimited volume. `environment` defaults to `dev`, the safest value. When you add a required field later, old objects fail on their next update, so prefer an optional field with a default.

This part wrote the schema, saw the API server reject a bad claim, fill in defaults and prune an unknown field. Some rules cannot be written with types and ranges alone, for example "a production database must have a standby replica". That rule compares two fields, and the next part adds it.

## Common pitfalls

> [!WARNING]
> - **Forgetting that stored objects are not re-checked.** A tighter schema does not remove old invalid objects. List them and fix them.
> - **Skipping `description`.** `kubectl explain` prints only what the schema contains.
> - **Putting `required` on the wrong node.** `required` lists the children of the object where it sits. A misplaced list gives no error until a request fails.
> - **Defaults without a parent.** A default inside an object that tenants may omit never applies.
> - **Relying on `--validate=ignore`.** It is a way to inspect pruning. A tenant who sees a field disappear learns nothing from silent pruning, so keep strict client validation on in normal work.
