# The Operator Pattern: CRD Plus Controller — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-080-playground-040-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with three
empty namespaces (`starfleet`, `beacon-system`, `beacon-registry`) and the image
`alpine/k8s:1.35.8` loaded. UNTESTED: built with static checks only. No CRD, no
operator. Nothing to submit.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-040/module-01/playground
astrona destroy ats-080-playground-040-01
```

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded image, bootstrap) |
| `bootstrap/prepare.sh` | Creates the three namespaces |
| `manifests/namespaces.yaml` | The namespaces |
| `docs/overview.md` | What the environment contains and ideas to try |
