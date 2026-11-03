# Providers, Identities, Connection Secrets And Deletion - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-080-playground-030-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading
- **Status:** UNTESTED (built with static checks only, never booted by the author)

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with Crossplane 2.4.3, provider-kubernetes v1.4.1 and function-patch-and-transform v0.11.2, a finished `Outpost` claim API (XRD and Composition `outpost-kubernetes`) and two claims, `scout` and `probe`. The provider identity is deliberately limited: it can manage namespaces, ConfigMaps and Services but not Deployments, so each claim is partly working. No cloud account is needed. Nothing to submit. The machine needs `helm` 3, `kubectl` and `jq`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-030/module-02/playground
astrona destroy ats-080-playground-030-02
```

`astrona destroy` takes the environment name (`metadata.name`), not the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, bootstrap) |
| `bootstrap/prepare.sh` | Installs Crossplane, the packages, the XRD, the Composition and the claims |
| `manifests/rbac-limited.yaml` | The limited ClusterRole and binding of the provider identity |
| `manifests/xrd-outpost.yaml` | The `Outpost` claim API with the connection secret key `endpoint` |
| `manifests/composition.yaml` | Four composed Objects: namespace, service, deployment, record |
| `manifests/claims.yaml` | The claims `scout` and `probe` in `starfleet` |
| `docs/overview.md` | What the environment contains and ideas to try |
