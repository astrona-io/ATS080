# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl` (1.27 or newer) and `jq`.
- You know how to write a CustomResourceDefinition with a schema, defaults, CEL rules and a status subresource, and how to write a Role, a RoleBinding and a ValidatingAdmissionPolicy.

The lab starts a single-node kind cluster (Kubernetes 1.35). No controller or extra image is needed. The cluster pulls the node image, so the machine needs access to the internet.
