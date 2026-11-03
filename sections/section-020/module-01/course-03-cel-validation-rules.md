---
draft: true
exam_objectives:
  - APIs for Self-Service Platforms (CRDs)
---
# CEL Validation Rules

Types, enumerations and ranges check one field at a time. Many platform rules involve two fields, or the old and the new version of an object. A production database must have a standby replica. A database engine must not change after the database exists. This part adds those rules to the CRD with the Common Expression Language (CEL), so the API server enforces them without a webhook or a controller.

## What CEL is

**CEL** is a small expression language from Google. An expression reads values and returns a result. It has no loops, no variables that change and no access to files or the network. Because of these limits, the API server can run an expression safely and can estimate its cost before it runs it.

Kubernetes embeds CEL in the CRD field `x-kubernetes-validations`. Each entry is a **validation rule**: an expression that must return `true`, and a message for the error when it returns `false`. CEL validation rules for CRDs are generally available (stable) since Kubernetes 1.29. The kube-apiserver evaluates them after defaulting and after the schema check passes, during create and update requests.

## Where a rule sits and what `self` is

A rule belongs to a schema node, and the keyword `self` refers to the value at that node. A rule on `spec` reads the whole `spec` as `self`. A rule on `spec.engine` reads only the engine string as `self`. Put the rule on the lowest node that holds every value it needs, because the error then points at the right field path.

Inside an expression you write field access with a dot: `self.environment`. For an optional field that has no default, test it first with `has(self.version)`, because reading an absent field is an error. Defaults apply before the rules run, so `self.environment` always exists in this schema.

The rule fields are:

| Field | Meaning |
| --- | --- |
| `rule` | The CEL expression. It must return a boolean. |
| `message` | The text of the error. |
| `messageExpression` | A CEL expression that builds the message from the values. It replaces `message`. |
| `reason` | The error type: `FieldValueInvalid` (the default), `FieldValueForbidden`, `FieldValueRequired` or `FieldValueDuplicate`. |
| `fieldPath` | A path below the node, such as `.highAvailability`, that the error points at. |
| `optionalOldSelf` | When `true`, a transition rule also runs on create, with `oldSelf` optional. |

## Add three rules

The change uses a JSON patch, because it adds keys at three places in the stored CRD. Save this as `crd-patch-cel.yaml`. A JSON patch is a list of operations, and `kubectl patch` accepts it in YAML form:

<!-- astrona:playground:renew -->

```yaml
- op: add
  path: /spec/versions/0/schema/openAPIV3Schema/properties/spec/x-kubernetes-validations
  value:
    - rule: "self.environment != 'prod' || self.highAvailability"
      message: "environment prod requires highAvailability: true"
      reason: FieldValueInvalid
      fieldPath: ".highAvailability"
- op: add
  path: /spec/versions/0/schema/openAPIV3Schema/properties/spec/properties/engine/x-kubernetes-validations
  value:
    - rule: "self == oldSelf"
      message: "engine cannot change after the claim is created"
- op: add
  path: /spec/versions/0/schema/openAPIV3Schema/properties/spec/properties/storageGB/x-kubernetes-validations
  value:
    - rule: "self >= oldSelf"
      message: "storageGB can grow but never shrink"
```

Apply it:

```sh
kubectl patch crd databaseclaims.platform.example --type=json --patch-file crd-patch-cel.yaml
```

Wait a few seconds, because the API server reloads the schema in the background. The first rule works on every create and update. The second and third use `oldSelf`, so they are **transition rules**: they compare the new value with the stored value and run only on update.

## Test the cross-field rule

Save a production claim without a standby replica as `databaseclaim-shuttle-db-prod.yaml`:

```yaml
apiVersion: platform.example/v1alpha1
kind: DatabaseClaim
metadata:
  name: shuttle-db
  namespace: starfleet
spec:
  engine: postgres
  environment: prod
```

Run it as a dry run:

```sh
kubectl apply --dry-run=server -f databaseclaim-shuttle-db-prod.yaml
```

The API server rejects the claim. The error names the path `spec.highAvailability` because of `fieldPath`, and it prints the message `environment prod requires highAvailability: true`. The tenant sees a plain sentence that states the platform rule, and no policy engine was needed.

Now add `highAvailability: true` to the file under `spec` and run the same command again. The dry run succeeds. The default for `highAvailability` is `false`, so a tenant who writes only `environment: prod` still fails, which is the intended result.

## Test the transition rules

A transition rule needs an existing object. The claim `scout-db` from earlier steps exists with `engine: postgres` and `storageGB: 20`. Try to change the engine:

```sh
kubectl patch dbc scout-db -n starfleet --type=merge -p '{"spec":{"engine":"mysql"}}'
```

The API server rejects the patch with the message `engine cannot change after the claim is created`. Now try to shrink and then to grow the volume:

```sh
kubectl patch dbc scout-db -n starfleet --type=merge -p '{"spec":{"storageGB":5}}'
kubectl patch dbc scout-db -n starfleet --type=merge -p '{"spec":{"storageGB":30}}'
```

The first command fails with `storageGB can grow but never shrink`. The second succeeds. The rules protect two facts that a controller could not undo: a database engine cannot be swapped in place, and a volume cannot shrink.

## Cost limits and what CEL cannot see

The API server estimates the cost of every rule when you apply the CRD. A rule that loops over an unbounded list or string can be expensive, so the CRD is rejected with a cost budget error. The fix is to bound the data in the schema with `maxLength`, `maxItems` or `maxProperties`. The rules above are cheap, because they compare single values.

CEL in a CRD sees only `self` and `oldSelf`. It cannot read another object, the name of the user who sends the request, or the labels of the namespace. A rule such as "only the platform team may create prod claims" does not fit here. That kind of rule belongs to RBAC or to a ValidatingAdmissionPolicy, and the second module of this section shows both.

## Rules, schema and defaults together

The three mechanisms run in a fixed order for each request. First the API server decodes the object, prunes unknown fields and applies defaults. Then it checks the schema keywords: type, required, enum and ranges. Last it runs the CEL rules. A rule can therefore rely on defaults and on valid types. A rule never has to repeat `enum`, which keeps rules short.

This part added three rules, saw a cross-field rule reject a production claim without a standby, and saw transition rules protect the engine and the size. The contract now rejects bad input, and the open question is how a tenant sees the state of a claim after it is accepted.

## Common pitfalls

> [!WARNING]
> - **Reading an optional field without `has()`.** A missing field makes the rule fail with an evaluation error instead of `true`.
> - **Expecting a transition rule on create.** `oldSelf` does not exist on create, so the rule is skipped unless `optionalOldSelf` is `true`.
> - **Unbounded strings and lists.** Rules over them can exceed the cost budget. Add `maxLength` and `maxItems`.
> - **A vague message.** The message is the only help a tenant gets. State the rule and the fix.
> - **Putting an identity rule in CEL.** A CRD rule cannot see who sends the request or the labels of the namespace.
