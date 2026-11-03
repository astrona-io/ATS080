# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. Command output is described in words, because names, times and keys differ on every run.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-040/capstone/labs/lab-01
```

Look at the starting state before you change anything:

```sh
kubectl -n starfleet get deployment,pod,certificate
kubectl -n cert-manager get deployments
```

The pod of `probe` is in `ContainerCreating`. The Certificate shows no value in the `READY` column. In `cert-manager`, the Deployment `cert-manager` shows `0/0`. The controller is not running.

## Step 1: Bring the controller back

A Certificate with an empty status means that nobody reconciles it. The API server accepted the object, because the webhook runs. The controller is the part that writes status. Scale it up and wait:

```sh
kubectl -n cert-manager scale deployment cert-manager --replicas=1
kubectl -n cert-manager rollout status deployment/cert-manager
kubectl -n kube-system get lease cert-manager-controller -o jsonpath='{.spec.holderIdentity}{"\n"}'
```

The lease has a holder name after a few seconds. Submit:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-040/capstone/labs/lab-01
```

The check `operator-running` passes. The others still fail.

## Step 2: Read why the Certificate is not Ready

The controller now reconciles the Certificate and reports the problem:

```sh
kubectl -n starfleet describe certificate probe-cert
```

The Ready condition says that the issuer `starfleet-ca` was not found. The `issuerRef` has the kind `ClusterIssuer`, and no ClusterIssuer exists. Create a selfSigned ClusterIssuer. Save this as `clusterissuer.yaml`:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: starfleet-ca
spec:
  selfSigned: {}
```

Apply it and check it:

```sh
kubectl apply -f clusterissuer.yaml
kubectl get clusterissuer starfleet-ca
```

The `READY` column shows `True`. A ClusterIssuer is cluster-scoped and can sign Certificates in any namespace, so this one resource serves `probe-cert` without a copy in `starfleet`.

## Step 3: Add the second DNS name

The Certificate becomes Ready after the issuer appears, but it covers only one name. Change `spec.dnsNames` so that it holds both names. Edit the object:

```sh
kubectl -n starfleet edit certificate probe-cert
```

The result of the `spec` must look like this:

```yaml
spec:
  secretName: probe-tls
  dnsNames:
    - probe.starfleet.svc
    - probe.starfleet.svc.cluster.local
  issuerRef:
    name: starfleet-ca
    kind: ClusterIssuer
```

A change of the spec makes cert-manager issue the certificate again and update the Secret. Wait for it:

```sh
kubectl -n starfleet wait --for=condition=Ready certificate/probe-cert --timeout=120s
kubectl -n starfleet get secret probe-tls
```

The Secret has the type `kubernetes.io/tls`. Submit now. The checks `issuer-ready` and `certificate-ready` pass.

## Step 4: Fix the volume of the Deployment

Describe the pod to see why it waits:

```sh
kubectl -n starfleet describe pod -l app=probe
```

The events say that the Secret `probe-certs` was not found. The Deployment names `probe-certs`, and the issued Secret is `probe-tls`. Replace the name in the volume:

```sh
kubectl -n starfleet patch deployment probe --type=json \
  -p '[{"op":"replace","path":"/spec/template/spec/volumes/0/secret/secretName","value":"probe-tls"}]'
kubectl -n starfleet rollout status deployment/probe
```

The rollout finishes, and one pod runs. Creating a Secret named `probe-certs` would also start a pod, but it would hide the mistake, and cert-manager would never renew it. Submit again. The check `probe-running` passes.

## Step 5: Remove the cluster-admin binding

Find out what the service account may do:

```sh
kubectl auth can-i get secrets --all-namespaces --as=system:serviceaccount:starfleet:probe
kubectl get clusterrolebindings -o wide | grep probe
```

The first command prints `yes`, and the second shows the binding `probe-admin` to the role `cluster-admin`. A web application does not need this. Delete the binding and keep the service account:

```sh
kubectl delete clusterrolebinding probe-admin
kubectl auth can-i get secrets --all-namespaces --as=system:serviceaccount:starfleet:probe
```

The second command prints `no` now. Submit the last time. All five checks pass.

## Why this works

Three different layers were broken: the operator was not running, an object referred to a resource that did not exist, and an application used the wrong name for the output of the operator. Each layer shows its own symptom. An empty status points to the controller, a condition message points to a missing reference, and a pod event points to a missing Secret. The extra binding is not a failure at all, and only a review of the RBAC finds it.

## Common mistakes

- Reading a missing status as a bad Certificate. Check the controller first.
- Creating an Issuer in `starfleet` instead of the ClusterIssuer. The Certificate refers to the kind `ClusterIssuer`, and an Issuer does not satisfy it.
- Creating a Secret by hand to start the pod. The Secret would not be owned or renewed by cert-manager.
- Deleting the service account together with the binding. The Deployment needs it.
