# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 3 GiB of free memory.
- `kubectl` and `jq`.
- You know the difference between `spec` and `status`, what `metadata.generation` and `status.observedGeneration` mean, and how `ownerReferences` connect a Deployment, a ReplicaSet and a pod.

The lab starts a single-node kind cluster (Kubernetes 1.35) with the Starfleet workloads. The cluster pulls the images, so the machine needs access to the internet.
