---
draft: true
exam_objectives:
  - Infrastructure Provisioning with Kubernetes
---
# Providers, Identities, Connection Secrets And Deletion

This module explains what happens at the edge of a claim, where Crossplane meets the system that holds the real resource. A provider needs an identity and permission to act. A finished resource can hand its address back to the developer through a secret. A claim can fail in part, and it can be deleted in ways that keep some resources. The module uses provider-kubernetes, so the real resource is a Kubernetes object and no cloud account is needed.

## Learning Goals

- Explain what a provider package installs and how a ProviderConfig and a service account give a provider its identity.
- Read the Synced and Ready conditions on a claim, a composite resource and a composed Object, and find the first failing object.
- Describe how a connection detail travels from a composed resource through the composite resource to a secret that the claim names.
- Explain management policies, the deletion policy of a managed resource and the delete policy of a claim.
- Predict which resources remain after a claim is deleted.

## Before You Start

You should know how a claim becomes a composite resource and composed resources. The hands-on steps use a playground with a working claim API and two claims that are only partly working. Technical terms are defined where they first appear.

## Reading Order

1. Providers, ProviderConfigs And Identity
2. Connection Secrets, Conditions And Partial Failure
3. Management Policies And Deletion
4. Summary

<!-- astrona:playground -->
