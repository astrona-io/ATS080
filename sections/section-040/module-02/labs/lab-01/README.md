---
estimated_duration: 30m
---

# Lab: Issue Certificates With cert-manager

Graded lab for the cert-manager module. **UNTESTED**: built with static checks only (`astrona validate`, `bash -n`, YAML parsing); it has not been run on a cluster. The cluster starts with cert-manager v1.21.3 (installed from the release manifest), the namespaces `starfleet` and `outpost`, and one Certificate in `outpost` that refers to a missing Issuer. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-040/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-040/module-02/labs/lab-01
astrona destroy ats-080-lab-040-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-scout-certificate-ready.sh` | `scout-cert` is Ready, uses a selfSigned Issuer in `starfleet` and lists both DNS names |
| `validate-scout-secret-issued.sh` | `scout-tls` has type `kubernetes.io/tls`, `tls.crt`, `tls.key` and the annotation naming `scout-cert` |
| `validate-scout-lifetime.sh` | `status.notAfter` minus `status.notBefore` is 48 hours, and `renewalTime` is 12 hours before `notAfter` |
| `validate-drifter-certificate-ready.sh` | `drifter-cert` is Ready and still refers to `Issuer/outpost-issuer` |
| `validate-scoped-issuers-only.sh` | No ClusterIssuer exists and the three cert-manager Deployments are unchanged |

## Open items (UNTESTED assumptions)

- cert-manager sets `status.notBefore`, `status.notAfter` and `status.renewalTime` on a Certificate, and the Secret annotation `cert-manager.io/certificate-name`.
- A Certificate that waits for a missing Issuer becomes Ready after the Issuer appears, without any edit.
- The start needs internet access to GitHub and `quay.io`.
