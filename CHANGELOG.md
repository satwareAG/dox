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

## 2026-11-24 - hook hardening

- `pre-commit` and `pre-push` compare the protected core byte-exactly with `cmp` (trailing newlines count; the previous `$(...)` extraction stripped trailing newlines and hid that edit class)
- `pre-push` resolves the baseline through `.githooks/baseline.sh`: pinned tag + SHA, fail closed on missing, moved, or rogue `v*-upstream` tags (the newest-tag heuristic is gone)
- Sync signal is now formal: staged SYNC.md must carry `Upstream-Commit: <40-hex-sha>`; a whitespace-only SYNC.md edit unlocks nothing. `pre-push` additionally requires the trailer in the sync commit message for a diverged core
- `pre-commit` secret scan runs the pattern layer in addition to betterleaks (entropy-gated rules miss low-entropy synthetic keys)
- `pre-commit` header comment corrected: betterleaks (was gitleaks)
- New controls: `negative-control-trailing-newline.sh`, `negative-control-whitespace-unlock.sh`, `positive-control-sync.sh`; CI runs all controls via glob
- SYNC.md: protocol step 1 adds the upstream remote when missing; step 4 formalizes the trailer + pin-bump requirements; hooks section documents the hardened behavior

## 2026-11-24 - installer + install-path spec

- `install.sh`: idempotent installer; installs the canonical template, appends the mandatory honesty addendum after the closing core marker, and manages opt-in addenda (`--site-release`, `--lazy-read`) as declared state - a re-run without a flag removes that block; a no-change re-run is byte-identical; the protected core is never modified; intact DOX marker pair required (refuses non-DOX targets)
- README: install path requires the installer or appending `addenda/honesty.md`; copying AGENTS.md alone is declared incomplete
- Canonical AGENTS.md: post-marker template notice (delimited `TEMPLATE-NOTICE-START/END`) states this file is the distributable template, not a project to scan; the installer replaces it with an installed-from line in installed copies
- Installer control: `.githooks/positive-control-install.sh` (idempotency, honesty mandatory, flag gating, core untouched)
- `addenda/lazy-read.md`: opt-in token-budget addendum (`--lazy-read`); chain-only reads for touched paths, one-line index entries, no repository overviews in always-loaded files, re-read only the owning chain, explicit tool reads (runtimes resolve nested AGENTS.md files differently). Stays outside the protected core: it is project-optional behavior, not the universal contract; the core stays byte-stable against the upstream baseline
