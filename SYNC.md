# SYNC - upstream sync protocol

- Upstream: https://github.com/agent0ai/dox (dormant since 2026-09-01)
- Baseline: tag `v0-upstream` pinned at commit 765ae4ac
- The canonical `AGENTS.md` core between the `DOX-CORE-START` and `DOX-CORE-END` markers stays byte-identical to `v0-upstream` except by an explicit, reviewed core upgrade

## Protocol

1. Add the upstream remote when missing: `git remote add upstream https://github.com/agent0ai/dox`; then fetch upstream: `git fetch upstream && git log --oneline v0-upstream..upstream/main`
2. Review core diffs only: `git diff v0-upstream upstream/main -- AGENTS.md`
3. Reject: reformatting, section reorder, rewording of core lines, whitespace churn
4. Adopt: apply reviewed core changes inside the marker range, keep the byte-stability contract, add a CHANGELOG entry citing the upstream commit, retag vN-upstream AT THE UPSTREAM FETCH COMMIT (never at a fork commit - fork commits carry the marker wrapper), and bump the pinned ref consumers use (`.githooks/baseline.sh`: tag name + SHA together). A core-change commit is the deliberate sync signal: it stages SYNC.md carrying an `Upstream-Commit: <40-hex-sha>` line naming the adopted upstream commit, and the commit message carries the same trailer. A whitespace-only SYNC.md edit is not a sync signal (hooks reject it)
5. If upstream wakes after long dormancy: re-review this protocol before merging anything

## Enforcement status (read before relying on the hooks)

- Branch protection on main is a 0-approval required-PR gate with `enforce_admins=false`: it is NOT review and NOT core enforcement. It blocks force-push and deletion; admins retain bypass
- Hooks are clone-local: contributors must run `git config core.hooksPath .githooks`, and `--no-verify` bypasses them entirely; web-UI PR merges bypass them
- Server-side verification = the CI workflow (`.github/workflows/verify.yml`): marker pair check, core byte-stability against the PINNED baseline via `.githooks/baseline.sh` (fails closed on missing, moved, or rogue `v*-upstream` tags - the newest tag is never trusted), secret scan over the PR diff (betterleaks, pattern-scan fallback, input coverage asserted), and the `.githooks/*control*` reject-path drivers. Branch protection (required-PR, 0 approvals, admin bypass) remains NOT review and NOT core enforcement. It blocks force-push and deletion; admins retain bypass
- Routine pushes should use a non-admin token so the force-push block binds writers; admin pushes are for reviewed syncs only

## Repository hooks

- Enable: `git config core.hooksPath .githooks`
- `pre-commit`: whitespace check; secret scan fail-fast in two layers - betterleaks (`betterleaks git --pre-commit --staged`) plus a pattern scan that always runs (entropy-gated scanner rules do not see low-entropy synthetic keys); marker-pair check; protected-core integrity compared byte-exactly with `cmp` (trailing newlines count). Core edits are blocked unless SYNC.md is staged AND carries an `Upstream-Commit: <40-hex-sha>` line naming the adopted upstream commit - a whitespace-only SYNC.md edit does not unlock anything
- `pre-push`: marker pair uniqueness + core byte-stability against the PINNED baseline via `.githooks/baseline.sh`, compared byte-exactly with `cmp`; fails closed on unreadable ranges, on missing/moved/rogue `v*-upstream` tags (the newest tag is never trusted), and on a diverged core whose pushed range lacks an `Upstream-Commit` trailer
- Test drivers (negative and positive controls): `negative-control-secret.sh`, `negative-control-core.sh`, `negative-control-push.sh`, `negative-control-baseline-missing.sh`, `negative-control-rogue-tag.sh`, `negative-control-trailing-newline.sh`, `negative-control-whitespace-unlock.sh`, `positive-control-clean.sh`, `positive-control-push.sh`, `positive-control-sync.sh`. CI (`.github/workflows/verify.yml`) runs every `*control*.sh` driver on each PR

## Reject conditions (hard)

- Any edit inside the DOX-CORE marker range that is not a reviewed upstream core change
- Promotion of addenda into the canonical `AGENTS.md`
- Reformat or reorder of core sections
- Unreviewed merges from upstream that touch `AGENTS.md`
