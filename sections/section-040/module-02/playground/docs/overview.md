# Overview: Operating A Real Operator: cert-manager (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with cert-manager installed, and then waits. There is no task, no `astrona submit` and no pass or fail. Issue certificates, break the operator, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it.
- **cert-manager v1.21.3**, installed from the release manifest `cert-manager.yaml` into the namespace `cert-manager`. Three Deployments run there: `cert-manager` (the controllers), `cert-manager-cainjector` and `cert-manager-webhook`. The release manifest also installs six CRDs, ClusterRoles and Roles, and one validating and one mutating webhook configuration.
- The namespaces `starfleet` and `outpost`, with no workload.
- No Issuer, no ClusterIssuer and no Certificate. You create them in the course steps.

## Useful commands

```sh
kubectl get crds | grep cert-manager
kubectl -n cert-manager get deployments
kubectl -n kube-system get leases
kubectl get validatingwebhookconfiguration cert-manager-webhook -o yaml
kubectl get events -A --field-selector involvedObject.kind=Certificate
```

## Practice tasks

- Create a selfSigned Issuer in `starfleet` and a Certificate for `scout.starfleet.svc`. Follow it through `Certificate`, `CertificateRequest` and `Secret`, and read the events.
- Change `spec.dnsNames` of the Certificate and watch cert-manager issue a new certificate into the same Secret.
- Create a Certificate that refers to an Issuer that does not exist, and read the condition message.
- Scale the `cert-manager` Deployment to zero. Create a new Certificate and see that nothing happens. Scale it back and see that the Certificate becomes Ready.
- Scale the `cert-manager-webhook` Deployment to zero and try to create an Issuer. Read the error, then scale it back.
- Run `kubectl get crd certificates.cert-manager.io -o jsonpath='{.status.storedVersions}'` and read which versions the CRD serves.
