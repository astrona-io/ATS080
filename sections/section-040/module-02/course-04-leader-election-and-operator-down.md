---
draft: true
exam_objectives:
  - Kubernetes Operator Pattern for Integration
---
# Leader Election And When The Operator Is Down

An operator is a set of running processes, and processes stop. They get rescheduled, they run out of memory, or an administrator scales them to zero during an incident. A platform engineer needs to know in advance which parts of the system keep working and which parts stop. This part separates the two: what the operator does for you while it runs, and what remains when it does not.

## Leader election: one active controller

A controller reconciles objects. If two replicas of the same controller reconcile the same Certificate at the same time, they can both create a CertificateRequest or both write the Secret. To avoid this, controllers that run with more than one replica use leader election. All replicas start, but only one holds the lock and does the work. The others wait and take over when the lock is released or expires.

The lock is an object in the API server. In current Kubernetes releases it is a `Lease` in the group `coordination.k8s.io`. The leader writes its own name into `spec.holderIdentity` and renews `spec.renewTime` at a fixed interval. If the leader stops renewing, the lease expires after `leaseDurationSeconds`, and another replica writes its own name. The default install of cert-manager puts these leases in the `kube-system` namespace.

## Try it: find the leases

<!-- astrona:playground:renew -->

```sh
kubectl -n kube-system get leases
kubectl -n kube-system get lease cert-manager-controller -o jsonpath='{.spec.holderIdentity}{"\n"}'
kubectl -n kube-system get lease cert-manager-cainjector-leader-election -o jsonpath='{.spec.renewTime}{"\n"}'
```

The list contains leases for the controller and for the cainjector. The holder identity is the pod name followed by a random suffix. Run the last command twice, some seconds apart. The renew time moves forward, and this shows that the leader is alive and working. The webhook has no lease, because it answers requests and does not reconcile in the background, so every replica can serve.

Each lease needs RBAC too. The controller holds a Role in `kube-system` that allows it to `get`, `create` and `update` leases. This is one more reason to read the permissions of an operator before you trust it: a namespace you did not expect, such as `kube-system`, receives objects from it.

## What stops when the controller stops

Scale the controller to zero and see what changes. The Deployment name is `cert-manager`:

```sh
kubectl -n cert-manager scale deployment cert-manager --replicas=0
kubectl -n cert-manager rollout status deployment cert-manager
kubectl -n starfleet get secret --field-selector type=kubernetes.io/tls
```

Secrets that already exist are ordinary Kubernetes objects. They stay, and every workload that mounts them keeps running. Nothing in the cluster depends on the controller process to read a Secret.

Now create a new Certificate while the controller is away. Use any issuer that already exists in the namespace:

```sh
kubectl -n starfleet apply -f - <<'YAML'
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: late-cert
spec:
  secretName: late-tls
  dnsNames:
    - late.starfleet.svc
  issuerRef:
    name: starfleet-issuer
    kind: Issuer
YAML
kubectl -n starfleet get certificate late-cert
kubectl -n starfleet get secret late-tls
```

The webhook is still running, so the Certificate is accepted and stored. The READY column stays empty, there is no status and there are no conditions, and the Secret does not exist. Nothing reconciles the object. The API server did its part. The operator is the component that turns the wish into a result.

Scale the controller back to one replica and watch the object catch up:

```sh
kubectl -n cert-manager scale deployment cert-manager --replicas=1
kubectl -n cert-manager rollout status deployment cert-manager
kubectl -n starfleet wait --for=condition=Ready certificate/late-cert --timeout=120s
kubectl -n starfleet get secret late-tls
```

The new pod acquires the lease, lists all Certificates and reconciles each one. This is the level-based design from the first module at work: the controller does not need to have seen the creation event, because it compares the desired state and the actual state at start. A controller that depended on events alone would lose the object.

## What stops when the webhook stops

The webhook is in the request path of every create and update of a cert-manager resource. Its configuration says what happens when it does not answer. Check it:

```sh
kubectl get validatingwebhookconfiguration cert-manager-webhook -o jsonpath='{.webhooks[0].failurePolicy}{"\n"}'
kubectl get validatingwebhookconfiguration cert-manager-webhook -o jsonpath='{.webhooks[0].rules}{"\n"}'
```

The policy is `Fail`. A request that matches the rules is rejected when the webhook cannot be reached. The rules match only resources in the groups of cert-manager, so other objects are not affected. Scale the webhook to zero and test both cases:

```sh
kubectl -n cert-manager scale deployment cert-manager-webhook --replicas=0
kubectl -n starfleet create configmap unaffected --from-literal=a=b
kubectl -n starfleet annotate certificate late-cert touched=yes --overwrite
```

The ConfigMap is created. The annotate command fails with an error that mentions the webhook and the service `cert-manager-webhook`, because the update of a Certificate has to pass the validating webhook. Scale the webhook back and repeat the command, and it works.

A failure policy of `Fail` is a deliberate choice. A webhook that validates input must not let invalid objects in when it is down. The cost is that an outage of the webhook blocks writes of its resource types. For a platform, this belongs in the runbook: a deployment pipeline that applies a Certificate fails while the webhook is down, and the fix is to restore the webhook and not to delete its configuration.

## What stops when the cainjector stops

The cainjector copies the CA certificate of the webhook into the `caBundle` field of the webhook configurations and CRDs that carry an annotation of cert-manager. The API server uses that bundle to trust the webhook. While the cainjector is down, the bundle that is already in place keeps working. The failure appears later: when the webhook certificate is renewed and the cainjector is not running, the bundle becomes stale, and the API server stops trusting the webhook. With `failurePolicy: Fail`, writes of cert-manager resources are then rejected. A quiet outage of a helper can turn into a visible outage days later, and a good monitor watches the helper too.

## A checklist for operator outages

For any operator, write down the answer to these four questions before an incident.

- What happens to the objects that already exist? Usually nothing: they keep working.
- What happens to new or changed custom resources? They are stored without a status, or they are rejected if a webhook is down.
- What catches up on restart? A level-based controller reconciles everything. Ask whether yours does.
- What do you check first? The Deployment status, the Lease holder, the events on the custom resource and the logs of the pod, in that order.

Scale everything back to its normal size when you finish, and check that the controller, the webhook and the cainjector are all available:

```sh
kubectl -n cert-manager get deployments
```

## Common pitfalls

> [!WARNING]
> - Do not delete the webhook configuration to get around a webhook outage. You lose validation, and the CRDs may accept objects that the controller cannot handle.
> - Do not read a missing status as a failed Certificate. With the controller down, the status is empty, and the condition appears only after the controller runs again.
> - A Lease that is renewed does not prove the work is correct. It only proves that the process is alive.
> - Scaling the controller to more than one replica does not make it faster. Only the leader reconciles, and the other replicas are standby.
> - Do not leave a component scaled to zero after a test. Nothing in the cluster reminds you.
