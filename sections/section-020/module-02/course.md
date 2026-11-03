---
draft: true
exam_objectives:
  - APIs for Self-Service Platforms (CRDs)
---
# Versions, Status Contracts And Tenant Access

A platform API is a long-term promise to its users. This module covers the three parts of that promise that change over time or protect the API: how versions evolve without breaking tenants, how the status tells a tenant what the platform did, and who may read or write each part. All of it works with a CRD, RBAC and the API server. No controller is needed.

The example is the `DatabaseClaim` kind in the group `platform.example`, now with two versions. The first part serves `v1alpha1` and `v1beta1` at the same time, moves the storage version and deprecates the old one. The second part writes status conditions through the status subresource and shows why `observedGeneration` matters. The third part grants tenant permissions with a Role and a RoleBinding, tests them with `kubectl auth can-i`, adds a ValidatingAdmissionPolicy for a rule that RBAC cannot express, and states what a CRD does not do.

## Learning Goals

- Explain served and stored versions, deprecation warnings and the `None` conversion strategy.
- Use status conditions and `observedGeneration` as a contract between a platform and its tenants.
- Grant a tenant group access to a custom resource with a namespaced Role, and keep status writes away from tenants.
- State the limits of a ValidatingAdmissionPolicy and explain why a CRD alone does nothing.

## Before You Start

You need to know what a CRD, a schema and the status subresource are, and basic RBAC: Role, RoleBinding and subject. The playground is a Kubernetes cluster with the namespaces `starfleet` and `outpost`, and the `DatabaseClaim` CRD already applied with both versions and the same schema.

<!-- astrona:playground -->

## Reading Order

1. Served And Stored Versions, Deprecation And Conversion
2. Status Conditions As A Contract
3. Tenant RBAC, Admission Limits And Why A CRD Alone Does Nothing
4. Summary
