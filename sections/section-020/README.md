---
draft: true
exam_objectives:
  - APIs for Self-Service Platforms (CRDs)
---
# APIs for Self-Service Platforms (CRDs)

A self-service platform lets a developer ask for what the team needs, such as a database or an environment, by writing a short YAML file and running `kubectl apply`. The Kubernetes API server is the front door for that request. A CustomResourceDefinition (CRD) extends the API server with a new kind, and the schema inside the CRD decides which requests the platform accepts. This section builds one such API, a `DatabaseClaim` in the group `platform.example`, from the first CRD to the permissions of the tenant teams.

The first module builds the contract of the API: the anatomy and scope of a CRD, an OpenAPI v3 schema with required fields, enumerations, limits and defaults, rules in the Common Expression Language (CEL), printer columns, the status subresource and `kubectl explain`. The second module keeps the contract over time and protects it: served and stored versions, deprecation and conversion, status conditions with `observedGeneration`, tenant permissions with RBAC, the limits of a ValidatingAdmissionPolicy, and why a CRD alone does nothing. No controller is needed. The hands-on work uses CRDs, RBAC and `kubectl`.

A capstone lab at the end defines a complete self-service API called `Environment` from an empty cluster: schema, defaults, validation, status subresource, tenant RBAC and an admission policy. The section ends with a knowledge check.

## Learning Outcomes

- Explain a CRD as an API contract that the API server enforces, and not as an implementation.
- Write a structural schema with required fields, enumerations, limits and defaults, and explain pruning.
- Write CEL validation rules, including transition rules that compare the old and the new object.
- Separate the desired specification from the observed status with the status subresource, and read status conditions with `observedGeneration`.
- Plan versions with served, stored and deprecated flags and the conversion strategy `None`.
- Grant tenant teams access to a custom resource with a namespaced Role, keep status writes away from them, and test it with `kubectl auth can-i`.
- State what a ValidatingAdmissionPolicy can and cannot enforce.
