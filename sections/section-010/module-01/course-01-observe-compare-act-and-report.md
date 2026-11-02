---
draft: true
exam_objectives:
- Kubernetes Reconciliation Loop
---
# Observe, Compare, Act And Report

Reconciliation is the process of bringing actual managed state toward authoritative desired state. It uses feedback rather than assuming that a past command sequence remains correct forever. An agent observes relevant conditions, compares them with intent, chooses supported action and records the result. Repeated evaluation allows it to respond to both new desired versions and unintended target changes.

Observation should identify the state being evaluated. The agent needs a desired revision and a current view of relevant target conditions. Rendering may translate higher-level input into concrete resources. Comparison then distinguishes already-satisfied conditions from differences that need action. Without this step, repeatedly executing a creation procedure can produce duplicates or undo legitimate external ownership.

Actions use target APIs and supported implementation contracts. They can create, update or remove managed resources according to policy. The agent may need to wait for another controller or external provider to complete work. An accepted API request is therefore not always the final result. The target can accept a resource while later reporting that capacity, credentials or dependencies prevent operation.

Consider a declaration requesting a service with three replicas. The agent can ensure the workload specification reflects that count. The scheduler and runtime then determine whether three instances become ready. If one cannot start, reconciliation should report the relevant condition rather than claim that a successful specification update proves all three are serving users.

Idempotency supports safe retries. Re-evaluating a satisfied declaration should not create another independent database or charge an external account again. The implementation needs stable identity, observation and supported update semantics. Some external operations are not naturally idempotent, so integrations may need operation identifiers or additional state to avoid repeating effects after uncertain results.

Convergence can be blocked. Invalid schema, denied permissions, absent capacity and conflicting ownership can prevent progress. A retry may help a temporary failure, while an invalid declaration requires a changed input. Unbounded rapid retries can overload the same failing dependency. Useful control behavior includes rate limits and errors that explain the contract needing repair.

Ordering and dependency handling are also policy. A system may need a namespace, secret or external capability before a workload can function. Agents differ in how they express dependencies and readiness. Creating every object without regard to these relationships can leave partial state that is syntactically present but operationally incomplete. Students should identify the actual controller's dependency contract rather than assume universal orchestration.

Feedback makes the process diagnosable. Status can identify the evaluated revision, attempted operation, observed condition and next relevant action. Events and metrics can show repeated failures or stale evaluation. This evidence should distinguish pending progress from terminal rejection and from successful convergence. A green process health endpoint has a much narrower scope.

Reconciliation is not unlimited authority. An agent can manage only the resources and fields assigned to it. Competing writers can prevent stable results even when both are healthy. External data and irreversible side effects may remain outside the configuration contract. The process should report those limits rather than promise to recreate every historical condition.

A good explanation follows one intended change through observation, action and outcome. It identifies which component owns each step and which evidence establishes success. That reasoning lets students evaluate unfamiliar controllers without confusing command completion, resource existence and application health.

## Common pitfalls

> [!WARNING]
> Reconciliation is feedback, not blind repetition. An accepted API write does not establish runtime readiness. Distinguish temporary retryable failure from invalid intent, absent capacity and ownership conflict, and avoid claiming that time alone guarantees convergence.
