# Changelog

Forward-only. One entry per adopted change after the `v0-upstream` baseline (agent0ai/dox commit 765ae4ac).

## 2026-11-24 - fork adoption + council roadmap

- Forked agent0ai/dox at 765ae4ac as satwareAG/dox; tagged `v0-upstream`
- Council roadmap adopted (5-seat debate, 3 rounds): protected core (#2), addenda files (#3), opt-in index convention (#4)
- Added SYNC.md (upstream sync protocol), CHANGELOG.md, README fork-status attribution

## 2026-11-24 - CI verification (issue #5, corrected)

- Added `.github/workflows/verify.yml` (PR + push to main + manual): full-history checkout (pinned actions SHA, fetch-depth 0 + explicit tag fetch), marker pair check, core byte-stability via `cmp` against the PINNED baseline (trailing newlines count; no `$(...)` stripping), secret scan over the PR diff (betterleaks with pattern fallback; empty scan input fails closed), and all five `.githooks` control drivers
- Added `.githooks/baseline.sh`: single source of truth for the upstream baseline pin (`v0-upstream` @ 765ae4ac); fails closed on missing, moved, or rogue `v*-upstream` tags - the newest local tag is never trusted
- Negative controls `negative-control-baseline-missing.sh` and `negative-control-rogue-tag.sh` prove the fail-closed paths
- SYNC.md "Enforcement status" updated: server-side verification is the CI workflow; branch protection remains explicitly not enforcement
