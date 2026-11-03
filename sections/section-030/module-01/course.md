---
draft: true
exam_objectives:
  - Infrastructure Provisioning with Kubernetes
---
# Claims, XRDs And Compositions

This module explains how a platform team turns a request for infrastructure into running resources with Crossplane. A developer creates a small claim object. Crossplane checks it against a schema, picks a recipe, and creates every resource that the recipe lists. The module follows that path one step at a time and ends with a claim that creates a namespace and a Deployment.

## Learning Goals

- Explain what a composite resource definition (XRD), a composite resource, a claim and a Composition each contain.
- Show how an XRD creates two new Kubernetes APIs and why a claim is namespaced while a composite resource is not.
- Read a Composition that uses a function pipeline with patch and transform, including patches, transforms and readiness checks.
- Follow a claim through reconciliation and read the references and conditions that show its progress.
- Explain what happens to the composed resources when a claim is changed or deleted.

## Before You Start

You should know what a custom resource definition, a controller and a namespace are. The hands-on steps use a playground with a kind cluster, Crossplane 2.4.3, the provider `provider-kubernetes` and the function `function-patch-and-transform`. No cloud account is needed, because the infrastructure in this module is a Kubernetes object that the provider creates in the same cluster. Technical terms are defined where they first appear.

## Reading Order

1. Claims, Composite Resources And XRDs
2. Compositions And Function Pipelines
3. Following A Claim Through Reconciliation
4. Summary

<!-- astrona:playground -->
