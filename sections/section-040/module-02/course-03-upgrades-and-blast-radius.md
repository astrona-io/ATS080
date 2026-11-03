---
draft: true
exam_objectives:
  - Kubernetes Operator Pattern for Integration
---
# Upgrades And Blast Radius

An operator is software that you upgrade, and it holds permissions that you must be able to account for. Two questions decide whether a platform team can run it safely. First: when the CRDs or the controller change, what happens to the objects that already exist? Second: if the controller misbehaves or an attacker takes it over, how much of the cluster can it reach? This part answers both from the objects in the cluster.

## CRD versions and what the API server stores

A CRD lists one or more versions. Each version has the fields `served` and `storage`. A served version answers requests. The storage version is the one the API server writes to etcd. Exactly one version has `storage: true`. When a client asks for a version that is not the storage version, the API server converts the object. For CRDs the conversion either changes only `apiVersion` (the default, `None`) or calls a conversion webhook that the operator provides.

The CRD status keeps `storedVersions`: every version in which some object has ever been written. The API server refuses to remove a version from `spec.versions` while it is still in `storedVersions`, because objects stored in that version could no longer be read. An operator that retires an old API version therefore migrates its stored objects first and then trims the list.

## Try it: read the versions

Look at the Certificate CRD:

<!-- astrona:playground:renew -->

```sh
kubectl get crd certificates.cert-manager.io -o jsonpath='{range .spec.versions[*]}{.name}{" served="}{.served}{" storage="}{.storage}{"\n"}{end}'
kubectl get crd certificates.cert-manager.io -o jsonpath='{.status.storedVersions}{"\n"}'
kubectl get crd certificates.cert-manager.io -o jsonpath='{.metadata.annotations}{"\n"}'
```

The first command prints one line, `v1 served=true storage=true`. The second prints a list with `v1`. The third shows the annotation `helm.sh/resource-policy` with the value `keep`. That annotation tells Helm, a package manager for Kubernetes, not to delete the CRD when the chart is removed.

A single version makes this install easy to upgrade. When the manifest of a newer release has the same version, there is nothing to convert. Older releases of cert-manager also served other API versions, and those were removed in later releases. A cluster that still had objects stored in a removed version had to migrate them before the upgrade.

## Why the CRDs go first

Upgrading a real operator has two kinds of change: the CRDs and the Deployments. They have to match, and the order matters.

A CRD schema is structural, and the API server prunes fields that the schema does not list. If you upgrade the controller to a version that expects a new field and the CRD is still old, the field the user writes is silently dropped when the object is stored. The controller then sees an object without the field. The reverse is also possible: new CRD fields with an old controller are stored and ignored.

The release manifest places the CRDs first, so a single `kubectl apply -f` of the new manifest updates the CRDs before the Deployments. With Helm, the CRDs need a separate decision, because Helm does not upgrade the files in the `crds` folder of a chart. The cert-manager chart offers a value to install the CRDs as part of the chart, and the `keep` annotation protects them on uninstall.

Rolling the controller back does not roll back the CRD. If a new CRD added a field and users have already written it, the old controller does not know the field. For this reason, an upgrade plan lists the CRD change, the controller image, the stored versions and the way back. The way back is often a restore from backup, and not a downgrade.

## Why deleting a CRD is different

Deleting a CRD deletes every object of that type in all namespaces. Deleting the `certificates.cert-manager.io` CRD removes every Certificate in the cluster. cert-manager does not set the Certificate as owner of the Secret it writes unless it is started with a flag for that, so the Secrets remain, but nothing renews them any more. The `keep` annotation and a rule that only administrators may delete CRDs are two defenses. A backup of the Certificate and Issuer manifests is a third.

## The permissions of the controller

Now the second question. Print the rules for the Certificates controller:

```sh
kubectl get clusterrole cert-manager-controller-certificates -o yaml
```

The rules list `certificates`, `certificaterequests`, `orders` and `issuers` with the verbs the controller needs. The last two rules matter most. One grants the verbs `get`, `list`, `watch`, `create`, `update`, `delete` and `patch` on `secrets`. The other grants `create` and `patch` on `events`. Both are in a ClusterRole, and a ClusterRoleBinding gives them to the service account `cert-manager`, so they apply in every namespace.

Ask the API server what the service account may do:

```sh
kubectl auth can-i get secrets -n kube-system --as=system:serviceaccount:cert-manager:cert-manager
kubectl auth can-i delete secrets -n starfleet --as=system:serviceaccount:cert-manager:cert-manager
kubectl auth can-i create pods -n starfleet --as=system:serviceaccount:cert-manager:cert-manager
kubectl auth can-i '*' '*' --as=system:serviceaccount:cert-manager:cert-manager
```

The first two print `yes`, the third prints `no` and the fourth prints `no`. cert-manager is not cluster-admin. It cannot create pods or change workloads. It can, however, read and replace any Secret in the cluster, because a certificate Secret can be in any namespace and the controller cannot know which Secrets are its own.

The cainjector has a different set of rights:

```sh
kubectl auth can-i update validatingwebhookconfigurations --as=system:serviceaccount:cert-manager:cert-manager-cainjector
kubectl auth can-i update customresourcedefinitions --as=system:serviceaccount:cert-manager:cert-manager-cainjector
kubectl auth can-i get secrets -n kube-system --as=system:serviceaccount:cert-manager:cert-manager-cainjector
```

All three print `yes`. The cainjector can change webhook configurations and CRDs, and it can read every Secret, though it cannot write them. A component that can edit the webhook configurations of a cluster can redirect or disable admission checks, so the permission deserves the same attention as a write permission on Secrets.

## Reading blast radius

Blast radius is the set of things that an operator can change or read if it fails or is compromised. You measure it from the RBAC objects, as above, and not from the documentation. Four questions give a useful answer.

- Which resources, and in which namespaces? A ClusterRole bound by a ClusterRoleBinding reaches every namespace. A Role reaches one.
- Which verbs? A `get` leaks data. An `update` on Secrets lets the operator replace a TLS key. An `update` on a webhook configuration changes admission for the whole cluster.
- Who can make the operator act? Any user who can create a Certificate asks the controller to write a Secret in that user's namespace. The Role and the namespace of the Certificate limit where the Secret goes.
- What watches the operator? The audit log records the requests that the operator's service account makes.

Some operators let you narrow the scope by flags or by installing one instance per namespace. cert-manager accepts a ClusterIssuer or Issuer by name, and it can run with extra RBAC rules removed, but the default install is cluster-wide, and so the right questions are about monitoring and network access to the controller, and not only about the manifest.

You now know how CRD versions limit an upgrade, why the CRDs and the controller must move together, and how to read the authority that an operator holds. The open question is how the operator behaves when parts of it stop.

## Common pitfalls

> [!WARNING]
> - Do not delete a CRD to "reset" an operator. The delete removes every custom resource of that type in all namespaces.
> - Do not upgrade the controller image alone. A new controller on old CRDs loses new fields without an error, because the API server prunes unknown fields.
> - Do not rely on a controller rollback to undo a CRD change. The CRD and the stored objects stay as they are.
> - A namespaced `Certificate` does not make the controller namespaced. The controller reads Secrets cluster-wide, and a ClusterRole is the reason.
> - `kubectl auth can-i --as` checks RBAC only. It does not show whether a webhook or another admission control would reject the request.
