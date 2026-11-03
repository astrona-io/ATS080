# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was written and checked with static checks only (it has not been run), so the outputs below are described and not copied.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-020/capstone/labs/lab-01
```

## Step 1: Define the CRD with schema, defaults, rules, status and columns

One file holds the whole contract. The spec-level rule checks the tier and the replicas, the rule on `owner` compares the new value with the stored value, and the status subresource separates the status from the spec. Save this as `crd-environment.yaml`:

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: environments.platform.example
spec:
  group: platform.example
  scope: Namespaced
  names:
    kind: Environment
    listKind: EnvironmentList
    plural: environments
    singular: environment
    shortNames:
      - env
  versions:
    - name: v1alpha1
      served: true
      storage: true
      subresources:
        status: {}
      additionalPrinterColumns:
        - name: Tier
          type: string
          jsonPath: .spec.tier
        - name: Owner
          type: string
          jsonPath: .spec.owner
        - name: Phase
          type: string
          jsonPath: .status.phase
        - name: Age
          type: date
          jsonPath: .metadata.creationTimestamp
      schema:
        openAPIV3Schema:
          type: object
          required:
            - spec
          properties:
            spec:
              type: object
              description: The environment a team asks for.
              required:
                - tier
                - owner
              x-kubernetes-validations:
                - rule: "self.tier != 'prod' || self.replicas >= 2"
                  message: "tier prod requires at least 2 replicas"
                  fieldPath: ".replicas"
              properties:
                tier:
                  type: string
                  description: Tier of the environment.
                  enum:
                    - dev
                    - staging
                    - prod
                owner:
                  type: string
                  description: Owning team. Cannot be changed after creation.
                  pattern: '^[a-z0-9-]{3,30}$'
                  x-kubernetes-validations:
                    - rule: "self == oldSelf"
                      message: "owner cannot change after the environment is created"
                replicas:
                  type: integer
                  description: Number of replicas.
                  minimum: 1
                  maximum: 10
                  default: 1
                region:
                  type: string
                  description: Region of the environment.
                  enum:
                    - eu-north
                    - eu-west
                  default: eu-north
                ttlDays:
                  type: integer
                  description: Days before the environment is removed.
                  minimum: 1
                  maximum: 90
                  default: 14
            status:
              type: object
              description: Observed state, written by the platform controller.
              properties:
                phase:
                  type: string
                observedGeneration:
                  type: integer
                  format: int64
                conditions:
                  type: array
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
kubectl apply -f crd-environment.yaml
kubectl wait --for=condition=Established crd/environments.platform.example --timeout=60s
```

Then check the result with a dry run. Save this as `environment-scout-dev.yaml`:

```yaml
apiVersion: platform.example/v1alpha1
kind: Environment
metadata:
  name: scout-dev
  namespace: starfleet
spec:
  tier: dev
  owner: scout-team
```

```sh
kubectl apply --dry-run=server -o yaml -f environment-scout-dev.yaml
kubectl explain environment.spec
```

The dry run prints the object with the defaults `replicas: 1`, `region: eu-north` and `ttlDays: 14`. Wait a few seconds and run it again if the API server answers that the kind is not known yet.

```sh
astrona submit --keep
```

## Step 2: Grant access with Roles and RoleBindings

Each team gets an editor Role in its own namespace. The auditors get a viewer Role in both. A Role without a RoleBinding grants nothing, so every Role is followed by its binding. Save this as `rbac-starfleet.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: environment-editor
  namespace: starfleet
rules:
  - apiGroups: ["platform.example"]
    resources: ["environments"]
    verbs: ["create", "get", "list", "watch", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: environment-editor
  namespace: starfleet
subjects:
  - kind: Group
    name: team-starfleet
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: environment-editor
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: environment-viewer
  namespace: starfleet
rules:
  - apiGroups: ["platform.example"]
    resources: ["environments"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: environment-viewer
  namespace: starfleet
subjects:
  - kind: Group
    name: auditors
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: environment-viewer
  apiGroup: rbac.authorization.k8s.io
```

Save this as `rbac-outpost.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: environment-editor
  namespace: outpost
rules:
  - apiGroups: ["platform.example"]
    resources: ["environments"]
    verbs: ["create", "get", "list", "watch", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: environment-editor
  namespace: outpost
subjects:
  - kind: Group
    name: team-outpost
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: environment-editor
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: environment-viewer
  namespace: outpost
rules:
  - apiGroups: ["platform.example"]
    resources: ["environments"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: environment-viewer
  namespace: outpost
subjects:
  - kind: Group
    name: auditors
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: environment-viewer
  apiGroup: rbac.authorization.k8s.io
```

Apply both files:

```sh
kubectl apply -f rbac-starfleet.yaml
kubectl apply -f rbac-outpost.yaml
```

Then check the result. The expected answers are `yes`, `no`, `no` and `yes`:

```sh
kubectl auth can-i create environments.platform.example -n starfleet --as=jean-luc --as-group=team-starfleet
kubectl auth can-i create environments.platform.example -n outpost --as=jean-luc --as-group=team-starfleet
kubectl auth can-i update environments.platform.example -n starfleet --subresource=status --as=jean-luc --as-group=team-starfleet
kubectl auth can-i list environments.platform.example -n outpost --as=guinan --as-group=auditors
```

```sh
astrona submit --keep
```

## Step 3: Restrict production with a ValidatingAdmissionPolicy

RBAC cannot read the labels of a namespace, and a CEL rule in the CRD cannot either. A ValidatingAdmissionPolicy can, through `namespaceObject`. Save this as `validatingadmissionpolicy-environment-prod.yaml`:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: environment-prod-namespaces
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
      - apiGroups: ["platform.example"]
        apiVersions: ["*"]
        operations: ["CREATE", "UPDATE"]
        resources: ["environments"]
  validations:
    - expression: "object.spec.tier != 'prod' || (has(namespaceObject.metadata.labels) && 'platform.example/prod-allowed' in namespaceObject.metadata.labels && namespaceObject.metadata.labels['platform.example/prod-allowed'] == 'true')"
      message: "prod environments are allowed only in namespaces labeled platform.example/prod-allowed=true"
```

Save this as `validatingadmissionpolicybinding-environment-prod.yaml`:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: environment-prod-namespaces
spec:
  policyName: environment-prod-namespaces
  validationActions: ["Deny"]
```

Apply both:

```sh
kubectl apply -f validatingadmissionpolicy-environment-prod.yaml
kubectl apply -f validatingadmissionpolicybinding-environment-prod.yaml
```

Then check the result. Save this as `environment-drifter-prod.yaml`:

```yaml
apiVersion: platform.example/v1alpha1
kind: Environment
metadata:
  name: drifter-prod
  namespace: outpost
spec:
  tier: prod
  owner: drifter-team
  replicas: 2
```

```sh
kubectl apply --dry-run=server -f environment-drifter-prod.yaml
kubectl apply --dry-run=server -n starfleet -f environment-drifter-prod.yaml
```

The first command is denied with the policy message because `outpost` has no label. The second succeeds. Wait a few seconds and repeat if the first command is accepted, because the policy needs a moment to become active.

```sh
astrona submit
```

## Common mistakes

- Missing `subresources.status` lets tenants write the status through the main endpoint.
- A default without the field in the schema is pruned. Define `default` inside the property.
- A policy without a binding does nothing. The binding needs `validationActions: ["Deny"]`.
- A ClusterRoleBinding to a tenant group gives access in every namespace. Use RoleBindings.
- Granting `*` on the group includes `environments/status`. List verbs and resources.
