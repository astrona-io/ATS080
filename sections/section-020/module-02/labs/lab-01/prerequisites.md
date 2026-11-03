# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl` (1.27 or newer) and `jq`.
- You know what a CustomResourceDefinition version is, what the status subresource does, and how a Role and a RoleBinding work.

The lab starts a single-node kind cluster (Kubernetes 1.35). No controller or extra image is needed. The cluster pulls the node image, so the machine needs access to the internet.
