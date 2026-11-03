# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was written and checked with static checks only (it has not been run), so the outputs below are described and not copied.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-030/module-02/labs/lab-01
```

## Step 1: Find the failing Object

List the Objects of the claim `scout` and read the conditions of the Deployment Object:

```sh
kubectl get objects.kubernetes.crossplane.io -l crossplane.io/claim-name=scout
kubectl get outposts.platform.starfleet.example -n starfleet
```

The Object for the Deployment shows `SYNCED` as `False`. Read its conditions:

```sh
kubectl get objects.kubernetes.crossplane.io -l crossplane.io/claim-name=scout -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.conditions[?(@.type=="Synced")].message}{"\n"}{end}'
```

The message of the Deployment Object contains `forbidden` and names the service account `provider-kubernetes`. That is the missing permission of the provider identity.

## Step 2: Grant Deployments and nothing else

Save this as `rbac-provider-deployments.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: provider-kubernetes-deployments
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: provider-kubernetes-deployments
subjects:
  - kind: ServiceAccount
    name: provider-kubernetes
    namespace: crossplane-system
roleRef:
  kind: ClusterRole
  name: provider-kubernetes-deployments
  apiGroup: rbac.authorization.k8s.io
```

Apply it:

```sh
kubectl apply -f rbac-provider-deployments.yaml
```

Then check the result:

```sh
kubectl auth can-i create deployments.apps --as=system:serviceaccount:crossplane-system:provider-kubernetes
kubectl wait --for=condition=Ready outposts.platform.starfleet.example/scout -n starfleet --timeout=300s
```

The first command prints `yes`. The provider retries failed Objects with a growing delay, so the claim can take a few minutes to become Ready.

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-030/module-02/labs/lab-01 --keep
```

## Step 3: Ask for a connection secret

A claim gets a connection secret only when it names one. Patch the claim:

```sh
kubectl -n starfleet patch outposts.platform.starfleet.example scout --type=merge -p '{"spec":{"writeConnectionSecretToRef":{"name":"scout-conn"}}}'
```

Then check the result:

```sh
kubectl -n starfleet get secret scout-conn -o jsonpath='{.data.endpoint}' | base64 -d; echo
```

It prints `scout.outpost-scout.svc.cluster.local:9898`. The Object `record` reads the field `data.endpoint` of its ConfigMap, Crossplane copies the key into the connection secret of the composite resource, and then into the secret of the claim.

## Step 4: Orphan the record

Edit the Composition and add `deletionPolicy: Orphan` under `spec`, next to `providerConfigRef`, in the `base` of the resource named `record`:

```sh
kubectl edit composition outpost-kubernetes
```

The edited part looks like this:

```yaml
          - name: record
            base:
              apiVersion: kubernetes.crossplane.io/v1alpha2
              kind: Object
              spec:
                deletionPolicy: Orphan
                providerConfigRef:
                  name: local-cluster
```

Crossplane creates a new Composition revision and updates the composite resources. Wait until the Object of `probe` carries the policy:

```sh
kubectl get objects.kubernetes.crossplane.io -l crossplane.io/claim-name=probe -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.deletionPolicy}{"\n"}{end}'
```

One line must show `Orphan`. Then delete the claim:

```sh
kubectl -n starfleet delete outposts.platform.starfleet.example probe
kubectl get namespace outpost-probe
kubectl -n starfleet-records get configmap record-probe
```

The namespace `outpost-probe` is removed after a short time, and the ConfigMap `record-probe` is still there. Submit all checks:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-030/module-02/labs/lab-01
```

When you are finished, remove the lab:

```sh
astrona destroy ats-080-lab-030-02
```
