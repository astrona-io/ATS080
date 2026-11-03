# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 3 GiB of free memory.
- `kubectl` and internet access. The lab start downloads the cert-manager v1.21.3 release manifest from GitHub and pulls images from `quay.io` and `ghcr.io`.
- You know how a CRD and a controller work together, what a Certificate, an Issuer and a ClusterIssuer are, and how RBAC bindings grant access.

The lab starts a single-node kind cluster (Kubernetes 1.35) with cert-manager installed and an application that does not work yet. The start takes several minutes. The commands are in the README of this folder.
