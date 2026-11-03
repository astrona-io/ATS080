# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was written and checked with static checks only (it has not been run), so the outputs below are described and not copied.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-020/module-02/labs/lab-01
```

## Step 1: Move the storage version and deprecate v1alpha1

Exactly one version must have `storage: true`, so change both flags in one request. Save this as `crd-patch-storage.yaml`:

```yaml
- op: replace
  path: /spec/versions/0/storage
  value: false
- op: replace
  path: /spec/versions/1/storage
  value: true
```

Apply it:

```sh
kubectl patch crd databaseclaims.platform.example --type=json --patch-file crd-patch-storage.yaml
```

Save this as `crd-patch-deprecate.yaml`:

```yaml
- op: add
  path: /spec/versions/0/deprecated
  value: true
- op: add
  path: /spec/versions/0/deprecationWarning
  value: "platform.example/v1alpha1 DatabaseClaim is deprecated; use platform.example/v1beta1"
```

Apply it:

```sh
kubectl patch crd databaseclaims.platform.example --type=json --patch-file crd-patch-deprecate.yaml
```

Then check the result. The first command lists the storage version and the second lists the stored versions:

```sh
kubectl get crd databaseclaims.platform.example -o jsonpath='{.spec.versions[?(@.storage==true)].name}{"\n"}'
kubectl get crd databaseclaims.platform.example -o jsonpath='{.status.storedVersions}{"\n"}'
```

The first command prints `v1beta1`. The second lists both versions, because the API server never removes a version from `storedVersions` by itself.

```sh
astrona submit --keep
```

## Step 2: Grant tenant access with Roles and RoleBindings

A Role lists permissions and a RoleBinding gives them to a group. Both objects are needed for each group. Save this as `role-database-claim-editor.yaml`:

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

Save this as `rolebinding-database-claim-editor.yaml`:

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

Save this as `role-database-claim-viewer.yaml`:

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

Save this as `rolebinding-database-claim-viewer.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: database-claim-viewer
  namespace: starfleet
subjects:
  - kind: Group
    name: auditors
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: database-claim-viewer
  apiGroup: rbac.authorization.k8s.io
```

Apply all four files:

```sh
kubectl apply -f role-database-claim-editor.yaml
kubectl apply -f rolebinding-database-claim-editor.yaml
kubectl apply -f role-database-claim-viewer.yaml
kubectl apply -f rolebinding-database-claim-viewer.yaml
```

Then check the result with impersonation. The expected answers are `yes`, `no`, `no`, `yes` and `no`:

```sh
kubectl auth can-i create databaseclaims.platform.example -n starfleet --as=jean-luc --as-group=team-starfleet
kubectl auth can-i update databaseclaims.platform.example -n starfleet --subresource=status --as=jean-luc --as-group=team-starfleet
kubectl auth can-i get databaseclaims.platform.example -n starfleet --as=worf --as-group=team-outpost
kubectl auth can-i list databaseclaims.platform.example -n starfleet --as=guinan --as-group=auditors
kubectl auth can-i delete databaseclaims.platform.example -n starfleet --as=guinan --as-group=auditors
```

```sh
astrona submit --keep
```

## Step 3: Write the Ready condition through the status subresource

The main endpoint ignores `status` when the subresource is on, so send the patch to `/status`. First read the generation:

```sh
kubectl get databaseclaim scout-db -n starfleet -o jsonpath='{.metadata.generation}{"\n"}'
```

The command prints `2`. Save this as `status-scout-db-ready.yaml`:

```yaml
status:
  phase: Ready
  observedGeneration: 2
  connectionSecretName: scout-db-conn
  conditions:
    - type: Ready
      status: "True"
      reason: Provisioned
      message: The database accepts connections.
      observedGeneration: 2
      lastTransitionTime: "2026-11-03T10:10:00Z"
```

Apply it to the status subresource:

```sh
kubectl patch databaseclaim scout-db -n starfleet --subresource=status --type=merge --patch-file status-scout-db-ready.yaml
```

Then check the result:

```sh
kubectl wait --for=condition=Ready databaseclaim/scout-db -n starfleet --timeout=30s
kubectl get databaseclaim scout-db -n starfleet -o jsonpath='generation={.metadata.generation} observed={.status.observedGeneration}{"\n"}'
```

The output is `generation=2 observed=2`.

```sh
astrona submit
```

## Common mistakes

- A Role without a RoleBinding grants nothing, so the `can-i` answer stays `no`.
- A bare `databaseclaims` in `kubectl auth can-i` can answer `no` for the wrong reason. Use `databaseclaims.platform.example`.
- Patching the status through the main endpoint changes nothing. Add `--subresource=status`.
- Writing `observedGeneration: 1` leaves the condition older than the spec. Use the generation that you read.
- Deleting and recreating the CRD deletes `scout-db`, and the last check fails.
