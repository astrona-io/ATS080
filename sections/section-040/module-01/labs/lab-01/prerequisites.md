# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl` and internet access. The node image is `kindest/node:v1.35.8` and the operator image is `alpine/k8s:1.35.8`.
- You can read a short bash script, you know what a ConfigMap, a Role and a RoleBinding are, and you know how a finalizer and an `ownerReference` work.

The lab starts a single-node kind cluster (Kubernetes 1.35) with a CRD, a starter operator and two resources. The start takes a few minutes. The commands are in the README of this folder.
