---
draft: true
exam_objectives:
- Kubernetes Operator Pattern for Integration
---
# Domain Controllers, Integration And Repeated Safe Actions

The operator pattern applies domain knowledge through a controller. It lets users express intent in a supported API while the implementation manages details such as creation, updates and selected recovery behavior. A database operator, for example, can interpret a database resource and coordinate workload or provider actions. The pattern does not mean every possible operational task is automated or safe by default.

The API and implementation are separate. A custom resource definition establishes recognized fields and versions. Controller code watches relevant resources, observes conditions and performs supported actions. External systems may add provider APIs, storage and identity dependencies. Installing the definition without a functioning controller leaves an accepted declaration with no implementation to satisfy it.

Domain knowledge gives the operator meaning. A generic controller can copy fields, while a database operator may understand topology, backup requests or version constraints under its supported model. The exact capabilities belong to that implementation. Students should not assume that every operator with a database-related name supports the same migration, backup or failover contract.

Consider an operator managing a cluster of stateful instances. A desired version change may require an ordered update or a compatibility check. Simply replacing every instance at once could violate availability or data requirements. The operator's domain logic should determine the supported sequence and report progress. A valid version field does not establish that every upgrade path is accepted.

Repeated actions must be safe. The controller can receive duplicate events or retry after uncertainty. It should observe what already exists and use stable identity before creating additional resources. An external side effect may need its own idempotency mechanism. A loop that blindly repeats provisioning commands can create cost and confusion rather than convergence.

Permissions define the operator's authority. It may need access to custom resources, child workloads, secrets or external providers. That authority should fit the intended scope. A namespaced API does not automatically prevent an overprivileged controller from affecting other tenants. User input must not become an unconstrained instruction to exercise every credential the controller holds.

Status communicates domain outcomes. Conditions can indicate that creation is pending, a dependency is unavailable or an update is blocked. The consumer should not have to interpret an internal exception as if it were an API contract. Useful status protects secrets and connects the requested version to observed results. Process health alone is narrower than successful domain management.

Deletion also has domain meaning. Finalizers can coordinate cleanup or retention before the API object disappears. A failed finalizer can leave deletion pending, and forced removal can bypass intended cleanup. Persistent data needs an explicit policy rather than an assumption that resource deletion is harmless. Operators should make their supported lifecycle understandable before users depend on it.

Upgrades can affect controller code, CRD versions and defaults. A new schema may require conversion, while a new controller can interpret the same input differently. Existing resources and clients need compatibility review. Rolling back the controller image does not automatically reverse every schema or external-resource change made during an upgrade.

The operator pattern is therefore a supported integration contract with real implementation responsibilities. Students should trace intent, observation, action and feedback, then identify the domain assumptions and authority involved. That reasoning helps assess both built-in platform capabilities and third-party operators without treating automation as a universal guarantee.

## Common pitfalls

> [!WARNING]
> A CRD is not the operator implementation, and process health is not domain readiness. Review permissions, repeated side effects, deletion and upgrade compatibility. Do not assume every similarly named operator provides the same recovery or data guarantees.
