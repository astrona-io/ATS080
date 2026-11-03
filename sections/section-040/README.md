---
draft: true
exam_objectives:
  - Kubernetes Operator Pattern for Integration
---
# Kubernetes Operator Pattern for Integration

An operator extends the Kubernetes API with a new resource type and runs a controller that makes the cluster match what the user wrote in that type. This section shows the pattern from both sides. First you build a small operator yourself: a CustomResourceDefinition, a reconcile loop that runs as a Deployment, status, owner references and a finalizer. Then you operate a real one, cert-manager, and read its install, its permissions, its upgrade rules and its behavior when parts of it stop.

The section has two modules and a capstone.

- **The Operator Pattern: CRD Plus Controller** builds a `Beacon` operator in bash and `kubectl`, with least-privilege RBAC and idempotent actions.
- **Operating A Real Operator: cert-manager** installs cert-manager v1.21.3, issues a certificate through a selfSigned Issuer, and studies CRD versions, blast radius, leader election and outages.
- **Capstone** repairs a broken integration: a stopped controller, a missing ClusterIssuer, a wrong Secret name and an over-privileged service account.

Read the parts in order. Each module has a playground for the hands-on steps and one graded lab. The labs are untested and built with static checks only.

## Learning Outcomes

- Explain the operator pattern: the CRD is the API, the controller is the behavior, and nothing happens without a running controller.
- Write a level-based, idempotent reconcile loop that creates what is missing and reports status with `observedGeneration`.
- Use owner references for same-namespace cleanup and finalizers for cleanup that references cannot do.
- Grant a controller only the permissions it needs, and verify them with `kubectl auth can-i --as`.
- Describe what an install of a real operator contains: CRDs, controllers, RBAC and webhooks.
- Read conditions and events to diagnose why an operator-managed resource is not ready.
- Reason about CRD version compatibility, the blast radius of an operator and what continues to work when the controller or its webhook is down.
