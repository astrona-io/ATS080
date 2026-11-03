# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 3 GiB of free memory.
- `kubectl` and internet access. The lab start downloads the cert-manager v1.21.3 release manifest from GitHub and pulls the images from `quay.io`.
- You know what a Certificate, an Issuer and a Secret are, and you can write a Kubernetes manifest.

The lab starts a single-node kind cluster (Kubernetes 1.35) with cert-manager installed. The start takes several minutes. The commands are in the README of this folder.
