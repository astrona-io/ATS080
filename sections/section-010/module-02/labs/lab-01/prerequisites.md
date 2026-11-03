# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 3 GiB of free memory.
- `kubectl` and `jq`.
- You know the `Available` and `Progressing` conditions of a Deployment, what `progressDeadlineSeconds` does, and how to read pod status and events.

The lab starts a single-node kind cluster (Kubernetes 1.35) with the Starfleet workloads. Starting takes a few minutes longer than usual, because the setup waits until two rollouts pass their progress deadline of 60 seconds. The cluster pulls the images, so the machine needs access to the internet.
