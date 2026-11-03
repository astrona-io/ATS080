---
draft: true
exam_objectives:
  - Kubernetes Operator Pattern for Integration
---
# Operating A Real Operator: cert-manager

A small operator fits on one page. A real operator ships CRDs, several controllers, RBAC, admission webhooks and a leader election, and the platform team that installs it takes on all of that. cert-manager is a widely used operator that issues and renews X.509 certificates, the files that prove the identity of a service and carry the keys for TLS (Transport Layer Security). This module installs it and follows one certificate from request to Secret.

Keep one idea in mind: **an installed operator is a set of components with their own permissions and failure modes, and you must know what each one does before you depend on it.**

The module has four parts. **What The Install Contains** lists the CRDs, the three Deployments, the RBAC and the two webhook configurations in the release manifest. **From Issuer To Secret** creates a selfSigned Issuer and a Certificate and reads the CertificateRequest, the conditions and the events. **Upgrades And Blast Radius** looks at CRD versions and at what the controller's permissions let it touch. **Leader Election And When The Operator Is Down** shows which parts fail, and how, when each component stops.

## Learning goals

After this module you can:

- List what the cert-manager release manifest installs and say what each component does.
- Create an Issuer and a Certificate, and follow the request through the CertificateRequest to a `kubernetes.io/tls` Secret.
- Read the `Ready` and `Issuing` conditions and the events to find why a Certificate is not issued.
- Explain how CRD versions and stored versions limit an upgrade, and why CRDs must be applied before the controllers.
- Read the RBAC of an operator and state what it can read and change, and what a compromised operator could do.
- Explain leader election, and predict what still works when the controller, the webhook or the cainjector is down.

## Before you start

You need to know what a Secret, a Deployment, a Role and a ClusterRole are, and how to apply YAML with `kubectl`. Terms are defined where they first appear.

Your playground is a single-node `kind` cluster running Kubernetes 1.35. It has these parts:

| Where | What it is |
| --- | --- |
| cert-manager v1.21.3 | Installed from the release manifest and ready, in the namespace `cert-manager`. |
| namespaces `starfleet`, `outpost` | Empty. Certificates for the exercises go here. |
| Issuers | None. You create them. |

`kubectl` already points at the cluster.

Launch your playground now and keep it running while you read:

<!-- astrona:playground -->
