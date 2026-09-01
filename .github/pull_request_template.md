## Summary

- **Branch goal:** `.opencode/branch-goals/<branch>.md` — one line recap
- **What:** the change in one sentence

## Phases

| # | Phase | Status |
|---|---|---|
| 1 | <phase title> | ✅ Complete / ⬜ Partial / ➖ Not started |
| 2 | <phase title> | ✅ Complete |

<!-- Fill from the branch's phase plan; each finished phase lists its own files in Changes -->

## Changes

- `<file-or-dir>` — what it does / why
- `<file-or-dir>` — …

## Verification

- [ ] Build: `./.opencode/scripts/xcode-tools.sh build` → `BUILD SUCCEEDED`
- [ ] Smoke: launch ok + screenshot at `.opencode/tmp/screenshots/<name>-<ts>.png`
- [ ] Review: `VERDICT: PASS` (reviewer session)

<!-- Evidence: paste the relevant [ok]/EXIT lines and the verdict block -->

## Related

- `<PR or issue links>` — e.g. parent branch PR, related issues

## Notes

- Deviations from the plan, follow-ups (e.g. out-of-scope leftovers the reviewer flagged), things next sessions should know
