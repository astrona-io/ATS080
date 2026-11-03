---
draft: true
exam_objectives:
  - APIs for Self-Service Platforms (CRDs)
---
# CRD Schemas And Validation

A platform team offers self-service when a developer can ask for a database, an environment or a namespace by writing one short YAML file and running `kubectl apply`. The file is an object of a new kind, and the Kubernetes API server must accept it, check it and store it, exactly as it does for a Deployment. A CustomResourceDefinition (CRD) is the object that teaches the API server a new kind. This module shows how a CRD is built and how its schema decides which requests the API accepts.

You work with one example API in the group `platform.example`: the kind `DatabaseClaim`. A tenant team writes a `DatabaseClaim` to say which database engine, size and environment it needs. No controller exists in this module. The CRD alone gives you an API endpoint, validation, defaults and storage, and that is enough to see every mechanism that shapes the contract between a platform team and its users.

The module has four parts. The first reads the anatomy of a CRD and the difference between namespaced and cluster scope. The second writes the OpenAPI v3 schema with required fields, enumerations, limits and defaults, and shows how the API server prunes unknown fields. The third adds Common Expression Language (CEL) rules in `x-kubernetes-validations` for checks that span several fields or compare the old and new object. The fourth adds printer columns, the status subresource and `kubectl explain` for custom resources.

## Learning Goals

- Describe the fields of a CustomResourceDefinition and choose namespaced or cluster scope.
- Write an `openAPIV3Schema` with required fields, enumerations, numeric limits and defaults, and explain pruning.
- Write CEL validation rules, including a transition rule that uses `oldSelf`.
- Add printer columns and a status subresource, and read the contract with `kubectl explain`.

## Before You Start

You need basic `kubectl` skills: `kubectl apply`, `kubectl get`, `kubectl describe` and the meaning of a namespace. You do not need to know CRDs, OpenAPI or CEL; each term is explained where it first appears. The playground is a single-node Kubernetes cluster with the namespaces `starfleet` and `outpost`. It has no controller and no custom resources, so the first step is to apply a CRD.

<!-- astrona:playground -->

## Reading Order

1. CRD Anatomy And Scope
2. Schemas, Required Fields, Enumerations And Defaults
3. CEL Validation Rules
4. Printer Columns, Status And kubectl explain
5. Summary
