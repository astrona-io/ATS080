---
draft: true
exam_objectives:
  - Infrastructure Provisioning with Kubernetes
---
# Connection Secrets, Conditions And Partial Failure

A developer asks for an outpost and then needs to know where it can be reached. The address is known only after the resource exists, and it must not be copied by hand into a ticket. Crossplane solves this with connection secrets: values that the platform reads from a finished resource and writes into a Kubernetes Secret that the developer can mount. This part follows one value on its way, and then shows how to read the state of a claim whose resources are not all healthy.

## The path of a connection detail

A connection detail travels through four objects, and each hop needs its own setting. If any hop is missing, the secret of the claim is empty or does not exist.

The first hop is in the composed resource. A provider-kubernetes `Object` can read a field of any object it can see and expose it as a connection detail. The list `connectionDetails` names the object by `apiVersion`, `kind`, `name` and `namespace`, a `fieldPath`, and the key `toConnectionSecretKey`. In this module the Object named `record` wraps a ConfigMap and reads the field `data.endpoint` from it. The provider writes the value into a Secret that the Object names in `writeConnectionSecretToRef`. When the field comes from a Secret, the provider decodes the base64 value first, so the key holds the plain text.

The second hop is in the Composition. In the patch-and-transform input, a composed resource lists `connectionDetails` with a `name` and a type. The type `FromConnectionSecretKey` copies a key of the composed resource secret into the secret of the composite resource. The Composition also sets `writeConnectionSecretsToNamespace`, because the composite resource is cluster-scoped and its secret needs a namespace.

The third hop is in the XRD. `connectionSecretKeys` lists the keys that may be published. A key that is not listed is dropped, so the XRD is where the platform team decides what a developer can see.

The fourth hop is in the claim. A claim publishes nothing unless it sets `spec.writeConnectionSecretToRef.name`. The secret is then created in the namespace of the claim, with the keys that passed the filter.

```mermaid
flowchart LR
    A["ConfigMap field"] --> B["Object secret"]
    B --> C["Composite secret"]
    C --> D["Claim secret"]
```

## What the settings look like

The first hop sits in the base of the composed resource. This is the part of the `record` resource that reads the endpoint and names the secret:

```yaml
connectionDetails:
  - apiVersion: v1
    kind: ConfigMap
    name: record-probe
    namespace: starfleet-records
    fieldPath: data.endpoint
    toConnectionSecretKey: endpoint
writeConnectionSecretToRef:
  name: example-record
  namespace: crossplane-system
```

In the Composition the name of that secret is patched from the composite resource, so each claim gets its own. The second hop is a short entry on the same resource:

```yaml
connectionDetails:
  - name: endpoint
    type: FromConnectionSecretKey
    fromConnectionSecretKey: endpoint
```

The key name `endpoint` must be the same on every hop. A typo on one of them does not cause an error, it only produces a secret without that key.

## Reading conditions top down

Every object in the chain carries the conditions `Synced` and `Ready`. `Synced` is about the last reconcile and `Ready` is about the state of the resource. They are independent. A resource can be synced and not ready, for example a Deployment that was created and is still starting. It can be ready and not synced, for example when the last update failed and the old resource still works.

The reasons help. `Synced` has the reasons `ReconcileSuccess`, `ReconcileError` and `ReconcilePaused`. `Ready` has the reasons `Available`, `Creating`, `Deleting` and `Unavailable`. The message holds the detail, usually an error from the API that the provider called.

## Partial failure

A composite resource has several composed resources, and Crossplane creates all of them that it can. There is no ordering. When one fails, the others are still created, and the composite resource is not ready. The claim shows `Ready` equal to `False`, while the namespace, the Service and the ConfigMap exist and work. A connection secret can already be published, because its source does not depend on the failing resource.

Partial failure has two consequences for the operator. The claim alone does not say what is wrong, so read down to the first object with `Synced` equal to `False`. And fixing the cause fixes the claim without recreating anything: Crossplane retries the failing object and the claim becomes ready once every composed resource is.

## Hands-on: read a secret and a partial failure

<!-- astrona:playground:renew -->

The playground has the claims `scout` and `probe`, each partly working. List the claims and the composed Objects of `probe`:

```sh
kubectl -n starfleet get outposts.platform.starfleet.example
kubectl get objects.kubernetes.crossplane.io -l crossplane.io/claim-name=probe
```

The claim is not ready, and three of its four Objects are. Read the conditions of the claim:

```sh
kubectl -n starfleet get outposts.platform.starfleet.example probe -o jsonpath='{range .status.conditions[*]}{.type}{"\t"}{.status}{"\t"}{.reason}{"\n"}{end}'
```

Ask the claim to publish a secret. Patch it:

```sh
kubectl -n starfleet patch outposts.platform.starfleet.example probe --type=merge -p '{"spec":{"writeConnectionSecretToRef":{"name":"probe-conn"}}}'
```

Then check the result:

```sh
kubectl -n starfleet get secret probe-conn -o jsonpath='{.data.endpoint}' | base64 -d; echo
kubectl -n crossplane-system get secrets
```

The value is `scout.outpost-probe.svc.cluster.local:9898`, taken from the record ConfigMap in the namespace `starfleet-records`. The listing of `crossplane-system` also shows the intermediate secrets that were written on the way: one for the composed Object and one for the composite resource. The secret of the claim appears only after the patch, which shows that the claim must ask for it.

## Where a missing secret comes from

When the secret does not appear, go back along the four hops. First, does the claim set `writeConnectionSecretToRef`? Second, does the XRD list the key in `connectionSecretKeys`? Third, does the Composition list the key in `connectionDetails` for the composed resource? Fourth, does the composed Object have a secret at all, with the key set? Reading the secrets in `crossplane-system` shows where the chain breaks.

You now know how one value travels from a resource to the secret of a claim, and how to read a claim that is only partly healthy. What is still open is what happens when claims and composed resources are deleted, and how to control it.

## Common pitfalls

> [!WARNING]
> A connection secret is not created by the XRD alone. The claim must name a secret, the key must be in `connectionSecretKeys` and the Composition must pass it on. Also, connection secrets hold the same sensitive values that they were read from, so treat the namespace of the claim as the place where those values may be read.
