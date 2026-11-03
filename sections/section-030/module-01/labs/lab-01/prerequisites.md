# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 4 GiB of free memory.
- `kubectl`, `jq` and `helm` (version 3 or newer) on your machine.
- You know what a Kubernetes custom resource is and how to read the status conditions of an object.

The lab starts a single-node kind cluster (Kubernetes 1.35) and installs Crossplane 2.4.3, provider-kubernetes v1.4.1 and function-patch-and-transform v0.11.2 with Helm and Crossplane packages. The cluster pulls the chart, the packages and the images, so the machine needs access to the internet. You need no cloud account: every external resource in this lab is a Kubernetes object.
