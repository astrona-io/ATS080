---
draft: true
exam_objectives:
  - Kubernetes Operator Pattern for Integration
---
# Summary: Operating A Real Operator

- A real operator is several parts: CRDs, a controller, a webhook and a cainjector, with ClusterRoles and bindings.
- A `selfSigned` Issuer plus a Certificate produces a TLS Secret. The Ready condition and the events say why a Certificate is not ready.
- CRDs list served and storage versions. `storedVersions` blocks removal of a version that still holds objects. Upgrade the CRDs and the controller together.
- Read the RBAC to find the blast radius. The controller reads and writes Secrets in every namespace, and the cainjector edits webhook configurations.
- Leader election uses a Lease. With the controller down, existing Secrets keep working and new Certificates wait for the controller to return. With the webhook down, writes of its resources fail.

<!-- astrona:playground:destroy -->
