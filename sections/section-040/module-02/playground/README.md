# Operating A Real Operator: cert-manager — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-080-playground-040-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with
cert-manager v1.21.3 installed from the release manifest and two empty
namespaces (`starfleet`, `outpost`). UNTESTED: built with static checks only.
No Issuer, no Certificate. Nothing to submit. The start downloads the manifest
from GitHub and needs internet access.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-040/module-02/playground
astrona destroy ats-080-playground-040-02
```

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, bootstrap) |
| `bootstrap/prepare.sh` | Installs cert-manager v1.21.3, waits for the webhook, creates the namespaces |
| `manifests/namespaces.yaml` | The namespaces |
| `docs/overview.md` | What the environment contains and ideas to try |
