# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was written and checked with static checks only (it has not been run), so the outputs below are described and not copied.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-020/module-01/labs/lab-01
```

## Step 1: Write the schema and the defaults

Replace the open schema. The file below keeps the name, group, scope and version of the CRD, and gives `spec` its required fields, enumerations, limits and defaults. Because the CRD name is the same, `kubectl apply` updates the CRD and keeps the claim `probe-db`.

Save this as `crd-databaseclaim-schema.yaml`:

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

Then check the result with a server-side dry run of a claim that sets only the engine. Wait a few seconds if the first try shows no defaults. Save the claim as `claim-check.yaml`:

```yaml
apiVersion: platform.example/v1alpha1
kind: DatabaseClaim
metadata:
  name: check
  namespace: starfleet
spec:
  engine: postgres
```

Run the dry run:

```sh
kubectl create --dry-run=server -o jsonpath='{.spec.storageGB} {.spec.environment} {.spec.highAvailability}{"\n"}' -f claim-check.yaml
```

The command prints `10 dev false`. Grade the first two checks:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-020/module-01/labs/lab-01 --keep
```

The checks `schema-rejects-invalid` and `defaults-applied` pass. The others still fail.

## Step 2: Add the CEL rules

The three rules need three places in the schema, so use a JSON patch. The rule on `spec` reads two fields. The rules on `engine` and `storageGB` use `oldSelf`, so they run only on updates.

Save this as `crd-patch-cel.yaml`:

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

Then check that the existing claim cannot change its engine. A dry run does not store the change:

```sh
kubectl -n starfleet patch databaseclaim probe-db --type=merge --dry-run=server -p '{"spec":{"engine":"mysql"}}'
```

The API server rejects the patch with the message of the rule. Grade again:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-020/module-01/labs/lab-01 --keep
```

The check `cel-rules` passes now.

## Step 3: Add the status subresource and the printer columns

Save this as `crd-patch-status.yaml`:

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

Then list the claims. Wait a few seconds if the new columns are missing:

```sh
kubectl get databaseclaims -n starfleet
```

The table has the columns `ENGINE`, `ENVIRONMENT`, `STORAGE`, `PHASE` and `AGE`. The task needs only the first three plus `PHASE`; the extra columns are allowed. Run the grader one last time without `--keep`:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-020/module-01/labs/lab-01
```

All six checks pass. Then remove the lab:

```sh
astrona destroy ats-080-lab-020-01
```
