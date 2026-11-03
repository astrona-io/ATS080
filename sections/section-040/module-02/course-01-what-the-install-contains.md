---
draft: true
exam_objectives:
  - Kubernetes Operator Pattern for Integration
---
# What The Install Contains

A team that adds cert-manager to a cluster usually runs one command and moves on. That command applies a manifest of nearly fourteen thousand lines, and every object in it has a reason. This part reads that manifest through the cluster, so you know what you have installed, which component runs where and which objects can break an unrelated request.

## One manifest, five kinds of content

The release manifest `cert-manager.yaml` for version v1.21.3 creates these objects. The counts come from the manifest itself.

| Kind | Count | What it is for |
| --- | --- | --- |
| Namespace | 1 | `cert-manager`, which holds the workloads |
| CustomResourceDefinition | 6 | The API: Certificate, CertificateRequest, Issuer, ClusterIssuer, Order and Challenge |
| Deployment | 3 | `cert-manager`, `cert-manager-cainjector`, `cert-manager-webhook` |
| ClusterRole, ClusterRoleBinding | 13 and 10 | The permissions of the three components, and view and edit roles for users |
| Role, RoleBinding | 3 and 3 | Leader election in `kube-system`, and the webhook's access to its own Secret |
| ValidatingWebhookConfiguration, MutatingWebhookConfiguration | 1 and 1 | Admission checks for cert-manager resources |
| Service, ServiceAccount | 3 and 3 | One per component |

The Order and Challenge resources belong to ACME (Automatic Certificate Management Environment), the protocol that public certificate authorities such as Let's Encrypt use. A selfSigned Issuer never creates them.

## Try it: list the parts

The playground has cert-manager installed already. Start with the API types:

<!-- astrona:playground:renew -->

```sh
kubectl get crds | grep cert-manager
```

The command lists six CRDs, all in the groups `cert-manager.io` and `acme.cert-manager.io`. Each CRD serves one version, `v1`. A resource such as an Issuer is only a record in etcd. Nothing acts on it until a controller runs.

Next, look at the workloads:

```sh
kubectl -n cert-manager get deployments
kubectl -n cert-manager get pods
```

Three Deployments, one replica each, and three pods. The three do different jobs.

## Three components, three jobs

The `cert-manager` Deployment runs the controllers. Its container is started by the manifest with the argument `--leader-election-namespace=kube-system`. The controllers are several reconcile loops in one process: one for Issuers, one for ClusterIssuers, one for Certificates, one for CertificateRequests, and others for ACME. The Certificates controller creates a private key, builds a CertificateRequest and, when the request is signed, writes the Secret. This is the part that holds the operator's logic.

The `cert-manager-webhook` Deployment runs an admission webhook server. An admission webhook is an HTTPS endpoint that the API server calls when someone creates or updates an object, before the object is stored. The cert-manager webhook validates every cert-manager resource, for example it rejects a Certificate with a duration under one hour, and a second webhook changes CertificateRequests when they are created.

The `cert-manager-cainjector` Deployment solves a trust problem. The API server calls the webhook over HTTPS and needs the certificate authority (CA) that signed the webhook's serving certificate. The webhook creates its own CA and stores it in the Secret `cert-manager-webhook-ca`. The cainjector reads the Secret and copies the CA into the `caBundle` field of the two webhook configurations, which carry the annotation `cert-manager.io/inject-ca-from-secret`. It also injects CA data into CRDs and API services that ask for it.

## The webhook configurations

Read the validating webhook configuration:

```sh
kubectl get validatingwebhookconfiguration cert-manager-webhook -o yaml
```

Look at four fields in the output. `rules` lists the API groups `cert-manager.io` and `acme.cert-manager.io`, version `v1`, the operations `CREATE` and `UPDATE` and the resources `*/*`. `failurePolicy` is `Fail`. `clientConfig.service` points at the Service `cert-manager-webhook` in the namespace `cert-manager`. `namespaceSelector` excludes namespaces that carry the label `cert-manager.io/disable-validation` with the value `true`.

`failurePolicy: Fail` means that the API server rejects a request when it cannot reach the webhook. The rules match only cert-manager resources, so a Pod or a ConfigMap is not affected. A cert-manager resource, however, cannot be created or updated while the webhook is down. A later part shows this with a test.

The mutating configuration has the same name. Its rule covers only `CREATE` of `certificaterequests`, with `failurePolicy: Fail` too.

## The permissions

Print the ClusterRoles that belong to the controllers:

```sh
kubectl get clusterroles | grep cert-manager
kubectl get clusterrolebindings | grep cert-manager
```

The first list has thirteen entries. Eight are named `cert-manager-controller-...` and have the controllers' rights for issuers, clusterissuers, certificates, orders, challenges, ingress-shim, approval and certificatesigningrequests. One, `cert-manager-cainjector`, belongs to the cainjector. One, `cert-manager-webhook:subjectaccessreviews`, lets the webhook ask the API server whether a user may use an issuer. The `cert-manager-view`, `cert-manager-edit` and `cert-manager-cluster-view` roles are aggregation roles: they add cert-manager resources to the built-in `view` and `edit` roles, so a user with the built-in `edit` role in a namespace can also create Certificates there.

ClusterRoles bound with a ClusterRoleBinding apply to every namespace. The permissions are cluster-wide because a Certificate in any namespace must be served. The next part follows one Certificate through these components. A later part reads the permissions in detail.

## What you can now say about the install

You can list the objects that the install creates and name the component that does each job: the controllers issue, the webhook validates, and the cainjector keeps the webhook's trust data current. You also know that two webhook configurations with `failurePolicy: Fail` sit in the request path of every cert-manager resource. The open question is what these components do when a user asks for a certificate.

## Common pitfalls

> [!WARNING]
> - `kubectl get crds` showing six CRDs does not mean cert-manager works. The CRDs are only the API. The three Deployments must be available too.
> - The webhook is ready later than the other pods. A `kubectl apply` of an Issuer right after the install can fail with a webhook error. Wait until the webhook pod is ready and retry.
> - Do not label a namespace with `cert-manager.io/disable-validation: "true"` to get past a webhook error. It removes validation for that namespace, and the CRD schema is the only check left.
> - The leader election Roles live in `kube-system`, not in `cert-manager`. A policy that blocks changes to `kube-system` can break the controller's election.
