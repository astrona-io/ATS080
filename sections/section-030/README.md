---
draft: true
exam_objectives:
  - Infrastructure Provisioning with Kubernetes
---
# Section 030: Infrastructure Provisioning with Kubernetes

Makes the reader able to offer infrastructure as a Kubernetes API and to explain how a request becomes real resources. A developer creates a claim. Crossplane checks it against a schema, selects a Composition, runs a function pipeline, and a provider creates the resources with its own identity. The section follows that path, the connection secret that comes back, and the deletion behavior. The labs run on kind with no cloud account: provider-kubernetes makes the external resource a Kubernetes object.

**Curriculum item covered:** Infrastructure Provisioning with Kubernetes

---

## What You Will Master

- Explain what an XRD, a composite resource, a claim and a Composition each contain, and why a claim is namespaced
- Write an XRD with a schema that the Kubernetes API server enforces
- Write a Composition with function-patch-and-transform: base objects, patches, transforms and readiness policies
- Follow a claim through the composite resource to the composed Objects and read Synced and Ready at each step
- Explain provider packages, ProviderConfigs and the split between identity and permission, and fix a forbidden error with least privilege
- Deliver a connection detail from a composed resource through the Composition and the XRD to a claim secret
- Read a partly failed claim and find the first failing object
- Choose between management policies, deletion policy and claim delete policy to keep a resource after a claim is deleted

---

## The Learning Path

### 1. Claims, XRDs And Compositions
*   **Module Reader:** **[Module 1: Claims, XRDs And Compositions](./module-01/course.md)**
*   **Hands-on Playground:** `sections/section-030/module-01/playground` - kind cluster with Crossplane 2.4.3, provider-kubernetes v1.4.1 and function-patch-and-transform v0.11.2. A ProviderConfig `local-cluster` and the namespaces `starfleet` and `starfleet-records`. No XRD, no Composition, no claim.
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-030/module-01/playground
    ```
*   **Graded Lab:** `sections/section-030/module-01/labs/lab-01` - write the Composition for a finished `Outpost` API so that a claim creates a namespace and a Deployment and reports the namespace in its status.

### 2. Providers, Identities, Connection Secrets And Deletion
*   **Module Reader:** **[Module 2: Providers, Identities, Connection Secrets And Deletion](./module-02/course.md)**
*   **Hands-on Playground:** `sections/section-030/module-02/playground` - the same cluster with a finished `Outpost` API, a provider identity that cannot create Deployments, and the claims `scout` and `probe`.
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-030/module-02/playground
    ```
*   **Graded Lab:** `sections/section-030/module-02/labs/lab-01` - grant least-privilege access for Deployments, publish a connection secret and keep the record of a deleted claim.

### Section Capstone Challenge
*   **Comprehensive Challenge:** Infrastructure Provisioning Capstone - `sections/section-030/capstone/labs/lab-01`
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-030/capstone/labs/lab-01
    astrona submit -c .
    ```
*   **Hands-on Objective:** Build the complete `Depot` claim API from an empty Crossplane: an XRD with a bounded schema, a Composition that creates a namespace, a Deployment and an orphaned record, two claims, a connection secret and a deletion that keeps the record.

---

## Ready for Assessment?

*   **Take the Section 030 Knowledge Check:** `sections/section-030/quiz.yaml`
