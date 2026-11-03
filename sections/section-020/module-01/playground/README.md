# CRD Schemas And Validation - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-080-playground-020-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading
- **Status:** UNTESTED. Built and checked with static checks only (`astrona validate`, `bash -n`, YAML parsing). It has not been started.

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with the tenant namespaces `starfleet` and `outpost`. No CRD exists at the start. No controller runs. Nothing to submit.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-020/module-01/playground
astrona destroy ats-080-playground-020-01
```

`astrona destroy` takes the environment name (`metadata.name`), not the config path. `astrona submit` and `astrona test` do not apply: there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime and starting manifests) |
| `manifests/` | Starting manifests |
| `docs/overview.md` | What the environment contains and ideas to try |
