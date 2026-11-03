# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was written and checked with static checks only (it has not been run), so the outputs below are described and not copied.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-030/module-01/labs/lab-01
```

## Step 1: Look at the claim API

The XRD already exists. Check that it is established and read the fields of the claim:

```sh
kubectl get xrd xoutposts.platform.starfleet.example
kubectl explain outpost.spec
```

The first command shows `ESTABLISHED` as `True`. The second shows `replicas` and the fields Crossplane adds to every claim, such as `compositionRef` and `writeConnectionSecretToRef`.

## Step 2: Save and apply the Composition

Save this as `composition-outpost.yaml`:

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: outpost-kubernetes
spec:
  compositeTypeRef:
    apiVersion: platform.starfleet.example/v1alpha1
    kind: XOutpost
  mode: Pipeline
  pipeline:
    - step: compose-outpost
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
                      fmt: "outpost-%s"
              - type: ToCompositeFieldPath
                fromFieldPath: spec.forProvider.manifest.metadata.name
                toFieldPath: status.namespace
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
                      fmt: "outpost-%s"
              - type: FromCompositeFieldPath
                fromFieldPath: spec.replicas
                toFieldPath: spec.forProvider.manifest.spec.replicas
```

Apply it:

```sh
kubectl apply -f composition-outpost.yaml
```

The `placeholder` values are replaced by the patches. The function `function-patch-and-transform` reads the `base` of each resource, applies the patches and returns the result to Crossplane.

Submit the first check:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-030/module-01/labs/lab-01 --keep
```

## Step 3: Save and apply the claim

Save this as `claim-outpost-scout.yaml`:

```yaml
apiVersion: platform.starfleet.example/v1alpha1
kind: Outpost
metadata:
  name: scout
  namespace: starfleet
spec:
  replicas: 2
```

Apply it:

```sh
kubectl apply -f claim-outpost-scout.yaml
```

Then check the result:

```sh
kubectl get outpost scout -n starfleet
kubectl get objects.kubernetes.crossplane.io
```

The claim shows `SYNCED` and `READY` columns. At first `READY` is `False`, because the Deployment takes some time to start. The composition does not order the two Objects, so the Deployment Object may report an error for a short time until the namespace exists. Crossplane retries on its own.

## Step 4: Wait for Ready and submit

```sh
kubectl wait --for=condition=Ready outpost/scout -n starfleet --timeout=300s
kubectl get xoutposts.platform.starfleet.example -o jsonpath='{.items[0].status.namespace}{"\n"}'
```

The second command prints `outpost-scout`. Submit all checks:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-030/module-01/labs/lab-01
```

When you are finished, remove the lab:

```sh
astrona destroy ats-080-lab-030-01
```
