# Convergence, Drift And Blocked Progress - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-080-playground-010-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading
- **Status:** UNTESTED. Built and checked with static checks only (`astrona validate`, `bash -n`, YAML parsing). It has not been started.

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`). The
Starfleet workloads run in `starfleet` and `outpost`: `scout` and `probe`
(two replicas each, with Services and a progress deadline of 60 seconds),
`shuttle` and `drifter` (clients that run `curl`). Only built-in Kubernetes
controllers are used, so nothing else is installed. Nothing to submit.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-010/module-02/playground
astrona destroy ats-080-playground-010-02
```

`astrona destroy` takes the environment name (`metadata.name`), not the config
path. `astrona submit` and `astrona test` do not apply: there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, starting manifests) |
| `manifests/starfleet.yaml` | Namespaces, Deployments and Services |
| `docs/overview.md` | What the environment contains and ideas to try |
