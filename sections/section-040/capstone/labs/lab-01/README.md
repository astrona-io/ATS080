---
estimated_duration: 45m
---

# Capstone: Repair A Broken Operator Integration

Advanced graded capstone for the operator section. **UNTESTED**: built with static checks only (`astrona validate`, `bash -n`, YAML parsing); it has not been run on a cluster. The cluster starts with cert-manager v1.21.3 installed, its controller scaled to zero, and an application `probe` in `starfleet` with a Certificate that cannot be issued. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-040/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-040/capstone/labs/lab-01
astrona destroy ats-080-capstone-040
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-operator-running.sh` | The three cert-manager Deployments have one available replica, six cert-manager CRDs exist and the lease `cert-manager-controller` has a holder |
| `validate-issuer-ready.sh` | The selfSigned ClusterIssuer `starfleet-ca` is Ready |
| `validate-certificate-ready.sh` | `probe-cert` is Ready, uses `starfleet-ca`, lists both names and the Secret `probe-tls` has type `kubernetes.io/tls` |
| `validate-probe-running.sh` | Deployment `probe` mounts `probe-tls` as volume `tls` at `/etc/probe/tls` and has an available replica |
| `validate-no-cluster-admin.sh` | No cluster-admin binding for `probe`, and `probe` cannot read Secrets cluster-wide |

## Open items (UNTESTED assumptions)

- The Secret annotation `cert-manager.io/alt-names` lists the DNS names of the issued certificate, separated by commas.
- The controller holds the lease `cert-manager-controller` in `kube-system` once it runs.
- A pod that mounts a missing Secret stays in `ContainerCreating` and starts after the volume name is corrected.
- The start needs internet access to GitHub, `quay.io` and `ghcr.io`.
