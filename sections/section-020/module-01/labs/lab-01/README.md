---
estimated_duration: 25m
---

# Lab: Tighten The DatabaseClaim CRD

Graded lab for the CRD schema module. **UNTESTED:** it was built and checked with static checks only (`astrona validate`, `bash -n`, YAML parsing) and has not been run or graded on a cluster. The cluster starts with an open `DatabaseClaim` CRD that accepts any spec, and one claim, `probe-db`. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-020/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS080.git -c sections/section-020/module-01/labs/lab-01
astrona destroy ats-080-lab-020-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-schema-rejects-invalid.sh` | Server-side dry runs reject five invalid claims and accept a valid one |
| `validate-defaults-applied.sh` | A dry-run create returns `10`, `dev` and `false` for the three defaulted fields |
| `validate-cel-rules.sh` | A prod claim needs a standby, the engine cannot change, the size cannot shrink (each rejection is paired with an accepted nearby change) |
| `validate-status-subresource.sh` | A write through `/status` is stored, and a write through the main endpoint is ignored |
| `validate-printer-columns.sh` | The CRD has the columns Engine, Environment and Phase with the right JSON paths |
| `validate-crd-and-claim-kept.sh` | `probe-db` has the UID recorded at start, and the version and scope are unchanged |

## Known risks

- The API server reloads a changed schema in the background. The checks retry for a few seconds before they fail.
- The reference solution waits eight seconds after the apply for the same reason.
- `validate-status-subresource.sh` leaves `status.phase` set to `Ready` on `probe-db`.
