# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was written and checked with static checks only (it has not been run), so the outputs below are described and not copied.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-030/capstone/labs/lab-01
```

## Step 1: Save and apply the XRD

The XRD is the contract. `claimNames` turns on the claim, `connectionSecretKeys` lists the keys a claim may receive, and the schema limits `replicas`. Save this as `xrd-depot.yaml`:

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: CompositeResourceDefinition
metadata:
  name: xdepots.platform.starfleet.example
spec:
  group: platform.starfleet.example
  names:
    kind: XDepot
    plural: xdepots
  claimNames:
    kind: Depot
    plural: depots
  connectionSecretKeys:
    - endpoint
  defaultCompositionRef:
    name: depot-kubernetes
  versions:
    - name: v1alpha1
      served: true
      referenceable: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                replicas:
                  type: integer
                  minimum: 1
                  maximum: 3
                  default: 1
```

Apply it:

```sh
kubectl apply -f xrd-depot.yaml
```

Then check the result:

```sh
kubectl wait --for=condition=Established xrd/xdepots.platform.starfleet.example --timeout=120s
kubectl wait --for=condition=Established crd/depots.platform.starfleet.example --timeout=120s
```

Crossplane creates two custom resource definitions from the XRD: one for `XDepot` and one for `Depot`.

## Step 2: Save and apply the Composition

Save this as `composition-depot.yaml`:

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: depot-kubernetes
spec:
  compositeTypeRef:
    apiVersion: platform.starfleet.example/v1alpha1
    kind: XDepot
  writeConnectionSecretsToNamespace: crossplane-system
  mode: Pipeline
  pipeline:
    - step: compose-depot
      functionRef:
        name: function-patch-and-transform
      input:
        apiVersion: pt.fn.crossplane.io/v1beta1
        kind: Resources
        resources:
          - name: namespace
            base:
              apiVersion: kubernetes.crossplane.io/v1alpha2
              kind: Object
              spec:
                providerConfigRef:
                  name: local-cluster
                forProvider:
                  manifest:
                    apiVersion: v1
                    kind: Namespace
                    metadata:
                      name: placeholder
            patches:
              - type: FromCompositeFieldPath
                fromFieldPath: metadata.labels[crossplane.io/claim-name]
                toFieldPath: spec.forProvider.manifest.metadata.name
                policy:
                  fromFieldPath: Required
                transforms:
                  - type: string
                    string:
                      type: Format
                      fmt: "depot-%s"
          - name: deployment
            base:
              apiVersion: kubernetes.crossplane.io/v1alpha2
              kind: Object
              spec:
                providerConfigRef:
                  name: local-cluster
                readiness:
                  policy: AllTrue
                forProvider:
                  manifest:
                    apiVersion: apps/v1
                    kind: Deployment
                    metadata:
                      name: scout
                      namespace: placeholder
                    spec:
                      replicas: 1
                      selector:
                        matchLabels:
                          app: scout
                      template:
                        metadata:
                          labels:
                            app: scout
                        spec:
                          containers:
                            - name: scout
                              image: ghcr.io/stefanprodan/podinfo:6.15.0
                              ports:
                                - containerPort: 9898
            patches:
              - type: FromCompositeFieldPath
                fromFieldPath: metadata.labels[crossplane.io/claim-name]
                toFieldPath: spec.forProvider.manifest.metadata.namespace
                policy:
                  fromFieldPath: Required
                transforms:
                  - type: string
                    string:
                      type: Format
                      fmt: "depot-%s"
              - type: FromCompositeFieldPath
                fromFieldPath: spec.replicas
                toFieldPath: spec.forProvider.manifest.spec.replicas
          - name: record
            base:
              apiVersion: kubernetes.crossplane.io/v1alpha2
              kind: Object
              spec:
                deletionPolicy: Orphan
                providerConfigRef:
                  name: local-cluster
                forProvider:
                  manifest:
                    apiVersion: v1
                    kind: ConfigMap
                    metadata:
                      name: placeholder
                      namespace: starfleet-records
                    data:
                      claim: placeholder
                      endpoint: placeholder
                connectionDetails:
                  - apiVersion: v1
                    kind: ConfigMap
                    name: placeholder
                    namespace: starfleet-records
                    fieldPath: data.endpoint
                    toConnectionSecretKey: endpoint
                writeConnectionSecretToRef:
                  name: placeholder
                  namespace: crossplane-system
            patches:
              - type: FromCompositeFieldPath
                fromFieldPath: metadata.labels[crossplane.io/claim-name]
                toFieldPath: spec.forProvider.manifest.metadata.name
                policy:
                  fromFieldPath: Required
                transforms:
                  - type: string
                    string:
                      type: Format
                      fmt: "record-%s"
              - type: FromCompositeFieldPath
                fromFieldPath: metadata.labels[crossplane.io/claim-name]
                toFieldPath: spec.connectionDetails[0].name
                policy:
                  fromFieldPath: Required
                transforms:
                  - type: string
                    string:
                      type: Format
                      fmt: "record-%s"
              - type: FromCompositeFieldPath
                fromFieldPath: metadata.labels[crossplane.io/claim-name]
                toFieldPath: spec.forProvider.manifest.data.claim
                policy:
                  fromFieldPath: Required
              - type: FromCompositeFieldPath
                fromFieldPath: metadata.labels[crossplane.io/claim-name]
                toFieldPath: spec.forProvider.manifest.data.endpoint
                policy:
                  fromFieldPath: Required
                transforms:
                  - type: string
                    string:
                      type: Format
                      fmt: "scout.depot-%s.svc.cluster.local:9898"
              - type: FromCompositeFieldPath
                fromFieldPath: metadata.uid
                toFieldPath: spec.writeConnectionSecretToRef.name
                transforms:
                  - type: string
                    string:
                      type: Format
                      fmt: "%s-record"
            connectionDetails:
              - name: endpoint
                type: FromConnectionSecretKey
                fromConnectionSecretKey: endpoint
```

Apply it:

```sh
kubectl apply -f composition-depot.yaml
```

The deletion policy `Orphan` sits on the `record` Object. The patch for the Object name and the patch for `connectionDetails[0].name` use the same format, because the connection detail must read the ConfigMap the Object creates.

## Step 3: Save and apply the claims

Save this as `claims-depot.yaml`:

```yaml
apiVersion: platform.starfleet.example/v1alpha1
kind: Depot
metadata:
  name: scout-depot
  namespace: starfleet
spec:
  replicas: 2
  writeConnectionSecretToRef:
    name: depot-conn
---
apiVersion: platform.starfleet.example/v1alpha1
kind: Depot
metadata:
  name: probe-depot
  namespace: starfleet
spec:
  replicas: 1
```

Apply it:

```sh
kubectl apply -f claims-depot.yaml
```

Then check the result:

```sh
kubectl -n starfleet wait --for=condition=Ready depots.platform.starfleet.example/scout-depot --timeout=300s
kubectl -n starfleet wait --for=condition=Ready depots.platform.starfleet.example/probe-depot --timeout=300s
kubectl -n starfleet get secret depot-conn -o jsonpath='{.data.endpoint}' | base64 -d; echo
```

The last command prints `scout.depot-scout-depot.svc.cluster.local:9898`. Submit the checks so far:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-030/capstone/labs/lab-01 --keep
```

## Step 4: Delete probe-depot and keep the record

Because the Composition already had `deletionPolicy: Orphan` when the claim was created, the Object of `probe-depot` carries it. Confirm and delete:

```sh
kubectl get objects.kubernetes.crossplane.io -l crossplane.io/claim-name=probe-depot -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.deletionPolicy}{"\n"}{end}'
kubectl -n starfleet delete depots.platform.starfleet.example probe-depot
kubectl -n starfleet-records get configmap record-probe-depot
```

The namespace `depot-probe-depot` is removed after a short time and the ConfigMap stays.

## Step 5: Prove the schema

```sh
kubectl -n starfleet create --dry-run=server -f - <<'YAML'
apiVersion: platform.starfleet.example/v1alpha1
kind: Depot
metadata:
  name: bounds-test
spec:
  replicas: 5
YAML
```

The API server rejects the object with an error that names `spec.replicas` and the maximum of 3. Submit all checks:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-030/capstone/labs/lab-01
```

When you are finished, remove the lab:

```sh
astrona destroy ats-080-capstone-030
```
