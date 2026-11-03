---
estimated_duration: 30m
---

# Lab: Versions, Status Condition And Tenant Access

Graded lab for the versions, status and access module. **UNTESTED:** it was built and checked with static checks only (`astrona validate`, `bash -n`, YAML parsing) and has not been run or graded on a cluster. The cluster starts with the `DatabaseClaim` CRD with two served versions, the claim `scout-db` and no permissions for any tenant. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-020/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-020/module-02/labs/lab-01
astrona destroy ats-080-lab-020-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-versions.sh` | One storage version (`v1beta1`), both versions served, `v1alpha1` deprecated with a warning that names `v1beta1`, conversion `None`, `storedVersions` lists `v1beta1`, and `scout-db` reads in both versions |
| `validate-tenant-access.sh` | `kubectl auth can-i` answers for three impersonated identities: the editor group, the auditors and an unrelated team |
| `validate-least-privilege.sh` | No wildcard in the Roles of `starfleet`, no grant of `databaseclaims/status`, no ClusterRoleBinding for the three groups |
| `validate-ready-condition.sh` | `scout-db` has a `Ready` condition with status `True`, a reason, a message, a time and an `observedGeneration` equal to `metadata.generation` |
| `validate-contract-intact.sh` | `scout-db` has the UID recorded at start, and a dry-run create with an unknown engine is rejected through both versions |

## Known risks

- The access checks use impersonation (`--as`, `--as-group`). They need the cluster administrator, which the lab provides.
- RBAC changes take effect quickly, and the checks retry for a few seconds.
