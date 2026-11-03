# Claims, XRDs And Compositions - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-080-playground-030-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading
- **Status:** UNTESTED (built with static checks only, never booted by the author)

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with Crossplane 2.4.3, provider-kubernetes v1.4.1 and function-patch-and-transform v0.11.2 installed and healthy. A `ProviderConfig` named `local-cluster` exists, the provider service account is bound to `cluster-admin`, and the namespaces `starfleet` and `starfleet-records` exist. No XRD, Composition or claim exists: the learner writes them. No cloud account is needed, because the external resources are Kubernetes objects. Nothing to submit. The machine needs `helm` 3, `kubectl` and `jq`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-030/module-01/playground
astrona destroy ats-080-playground-030-01
```

`astrona destroy` takes the environment name (`metadata.name`), not the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, bootstrap) |
| `bootstrap/prepare.sh` | Installs Crossplane with Helm, applies the packages, waits for health |
| `manifests/packages.yaml` | Runtime configuration, provider and function packages |
| `manifests/providerconfig.yaml` | The ProviderConfig `local-cluster` |
| `manifests/rbac-admin.yaml` | Binds the provider service account to `cluster-admin` |
| `manifests/namespaces.yaml` | The namespaces `starfleet` and `starfleet-records` |
| `docs/overview.md` | What the environment contains and ideas to try |
