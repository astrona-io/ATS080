---
draft: true
exam_objectives:
  - APIs for Self-Service Platforms (CRDs)
---
# Tenant RBAC, Admission Limits And Why A CRD Alone Does Nothing

A self-service API has two audiences. Tenant teams create claims in their own namespace and must not touch the claims of other teams. The platform controller writes status and must be the only identity that does. This part grants those permissions with Role-based access control (RBAC), tests them with `kubectl auth can-i`, adds a ValidatingAdmissionPolicy for a rule that RBAC cannot express, and ends with a clear statement of what a CRD does not do.

## RBAC treats custom resources like built-in ones

RBAC is the Kubernetes authorization system. A **Role** lists permissions inside one namespace, and a **RoleBinding** gives a Role to users or groups. A permission is a rule with three parts: the API group, the resource and the verbs. For a custom resource, the group is the group of the CRD and the resource is the plural name. The `DatabaseClaim` kind therefore uses the group `platform.example` and the resource `databaseclaims`.

A subresource is a separate resource name with a slash. The status endpoint is `databaseclaims/status`. A rule for `databaseclaims` does not cover `databaseclaims/status`, and that gap is the point: the tenant Role names only `databaseclaims`, so tenants cannot write status.

The API server authenticates the user before it checks RBAC. The playground has no real users, so the checks below use **impersonation**. The flags `--as` and `--as-group` make `kubectl` send a request as another identity. The cluster administrator may impersonate any identity.

## Create a tenant Role and a read-only Role

Save this as `role-database-claim-editor.yaml`. It lets a tenant manage claims in the namespace `starfleet`:

<!-- astrona:playground:renew -->

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: database-claim-editor
  namespace: starfleet
rules:
  - apiGroups: ["platform.example"]
    resources: ["databaseclaims"]
    verbs: ["create", "get", "list", "watch", "update", "patch", "delete"]
```

Save this as `rolebinding-database-claim-editor.yaml`. It gives the Role to the group `team-starfleet`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: database-claim-editor
  namespace: starfleet
subjects:
  - kind: Group
    name: team-starfleet
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: database-claim-editor
  apiGroup: rbac.authorization.k8s.io
```

Apply both:

```sh
kubectl apply -f role-database-claim-editor.yaml
kubectl apply -f rolebinding-database-claim-editor.yaml
```

Now ask the API server what the identity `jean-luc` in the group `team-starfleet` may do. Each command prints `yes` or `no`:

```sh
kubectl auth can-i create databaseclaims.platform.example -n starfleet --as=jean-luc --as-group=team-starfleet
kubectl auth can-i create databaseclaims.platform.example -n outpost --as=jean-luc --as-group=team-starfleet
kubectl auth can-i update databaseclaims.platform.example -n starfleet --subresource=status --as=jean-luc --as-group=team-starfleet
kubectl auth can-i delete customresourcedefinitions.apiextensions.k8s.io --as=jean-luc --as-group=team-starfleet
```

The answers are `yes`, `no`, `no` and `no`. The group can create claims in its own namespace. It has no rule in `outpost`, which is the default result when no rule matches. It cannot write the status of a claim. It cannot change the CRD, because the CRD is a cluster-scoped resource and the Role is namespaced.

The resource name has the form `databaseclaims.platform.example`, which is `<resource>.<group>`. Without the group, `kubectl auth can-i` looks for a core resource of that name and answers `no` for the wrong reason.

## A read-only Role and the platform controller

An auditor group needs to read claims and change none. A second Role carries only read verbs. The Role of the platform controller would list `databaseclaims/status` with the verbs `get`, `update` and `patch`, and nothing else would. Save the read-only Role as `role-database-claim-viewer.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: database-claim-viewer
  namespace: starfleet
rules:
  - apiGroups: ["platform.example"]
    resources: ["databaseclaims"]
    verbs: ["get", "list", "watch"]
```

Apply it and list the Roles in the namespace:

```sh
kubectl apply -f role-database-claim-viewer.yaml
kubectl get role -n starfleet
```

The list shows both Roles. A Role is only a set of permissions until a RoleBinding names a subject, so the viewer Role gives nothing yet. Keep this in mind for the lab: both parts, the Role and the RoleBinding, must exist.

Platform teams often also add labels to a ClusterRole so that the built-in `view`, `edit` and `admin` roles include the new resource. The label `rbac.authorization.k8s.io/aggregate-to-edit: "true"` on a ClusterRole adds its rules to `edit`. That is convenient, but it widens access in every namespace where someone has `edit`, so a deliberate tenant Role is easier to audit.

## What RBAC cannot express

RBAC decides on the verb, the resource, the namespace and the name. It does not look inside the object. You cannot write "this group may create claims, but only with `environment: dev`". The rule needs the content of the request, and RBAC never reads it.

The CEL rules in the CRD read the object, but they cannot see the namespace or the user. A **ValidatingAdmissionPolicy** (VAP) fills this gap. It is a CEL policy that the API server evaluates during admission, which is the step after authorization and before storage. Its expressions can read `object`, `oldObject`, `request` (including `request.userInfo`) and `namespaceObject`. The API `admissionregistration.k8s.io/v1` has been stable since Kubernetes 1.30.

The namespace `starfleet` carries the label `platform.example/prod-allowed: "true"` and `outpost` has no such label. Check it:

```sh
kubectl get namespace starfleet outpost --show-labels
```

Save a policy that allows production claims only in labeled namespaces as `validatingadmissionpolicy-databaseclaim-prod.yaml`:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: databaseclaim-prod-namespaces
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
      - apiGroups: ["platform.example"]
        apiVersions: ["*"]
        operations: ["CREATE", "UPDATE"]
        resources: ["databaseclaims"]
  validations:
    - expression: "object.spec.environment != 'prod' || (has(namespaceObject.metadata.labels) && 'platform.example/prod-allowed' in namespaceObject.metadata.labels && namespaceObject.metadata.labels['platform.example/prod-allowed'] == 'true')"
      message: "prod claims are allowed only in namespaces labeled platform.example/prod-allowed=true"
```

A policy does nothing until a binding connects it to requests. Save this as `validatingadmissionpolicybinding-databaseclaim-prod.yaml`:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: databaseclaim-prod-namespaces
spec:
  policyName: databaseclaim-prod-namespaces
  validationActions: ["Deny"]
```

Apply both and test them with dry runs after a few seconds:

```sh
kubectl apply -f validatingadmissionpolicy-databaseclaim-prod.yaml
kubectl apply -f validatingadmissionpolicybinding-databaseclaim-prod.yaml
```

Save a production claim as `databaseclaim-drifter-db-prod.yaml`. It satisfies the CRD rule with a standby replica:

```yaml
apiVersion: platform.example/v1beta1
kind: DatabaseClaim
metadata:
  name: drifter-db
  namespace: outpost
spec:
  engine: postgres
  environment: prod
  highAvailability: true
```

Run it as a dry run in `outpost`, then in `starfleet`:

```sh
kubectl apply --dry-run=server -f databaseclaim-drifter-db-prod.yaml
kubectl apply --dry-run=server -n starfleet -f databaseclaim-drifter-db-prod.yaml
```

The first command is denied with the policy message, because `outpost` has no label. The second succeeds, because the namespace `starfleet` has it. The `-n` flag overrides the namespace in the file. The policy applies to every identity, including the cluster administrator, unless the policy excludes it.

## The limits of admission policy

A ValidatingAdmissionPolicy checks requests. It does not change an object, and it does not look at objects that already exist, so a claim created before the policy stays. It reads only the request, the namespace and an optional parameter object; it cannot list other claims to enforce "at most three claims per team". It runs on create and update, not on read. The field `failurePolicy: Fail` rejects requests when the expression itself fails, which is the safe choice for a rule that guards production.

## Why a CRD alone does nothing

Everything in this module happened inside the API server and etcd. List the claims and read the connection Secret name from the status:

```sh
kubectl get dbc -n starfleet
kubectl get dbc scout-db -n starfleet -o jsonpath='{.status.connectionSecretName}{"\n"}'
```

The status holds only what a person wrote through the status endpoint. If nobody writes it, the status stays empty. No pod starts, no database appears, and no Secret holds connection details. A CRD adds an API. It does not add behavior. A **controller** is a program that watches objects of the kind, compares the spec with the real world and writes the status. Without one, a claim is a record that nobody reads. With strong schema, rules and RBAC, the record is at least valid and owned by the right team.

This part granted permissions per namespace, tested them without real users, added a policy for a content rule, and named the missing piece. The contract of the API is now complete: schema, rules, versions, status and access.

## Common pitfalls

> [!WARNING]
> - **Forgetting the group in `can-i`.** Write `databaseclaims.platform.example`. A bare `databaseclaims` can answer `no` for the wrong reason.
> - **A Role without a RoleBinding.** The Role grants nothing until a binding names a subject.
> - **Granting `*` on the group.** It includes the status subresource and any resource added later. List verbs and resources.
> - **Using a ClusterRoleBinding for tenants.** It grants access in every namespace. Use a RoleBinding in the tenant namespace.
> - **A policy without a binding.** The ValidatingAdmissionPolicy does nothing until a binding with `validationActions` exists.
> - **Expecting objects to be created by the CRD.** A claim stays a record until a controller acts on it.
