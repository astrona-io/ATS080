---
draft: true
exam_objectives:
- Kubernetes Operator Pattern for Integration
---
# Summary

An operator combines domain knowledge with a control loop that interprets declared resources and manages assigned systems. A CRD supplies the API contract, while controller code performs and observes the work. Integrations need scoped permissions and safe repeated behavior. Upgrades can change schemas, defaults and lifecycle, so controller availability alone does not establish compatibility. Useful status makes pending and failed domain operations understandable to consumers.
