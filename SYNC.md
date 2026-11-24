# SYNC - upstream sync protocol

- Upstream: https://github.com/agent0ai/dox (dormant since 2026-09-01)
- Baseline: tag `v0-upstream` pinned at commit 765ae4ac
- The canonical `AGENTS.md` core between the `DOX-CORE-START` and `DOX-CORE-END` markers stays byte-identical to `v0-upstream` except by an explicit, reviewed core upgrade

## Protocol

1. Add the upstream remote when missing: `git remote add upstream https://github.com/agent0ai/dox`; then fetch upstream: `git fetch upstream && git log --oneline v0-upstream..upstream/main`
2. Review core diffs only: `git diff v0-upstream upstream/main -- AGENTS.md`
3. Reject: reformatting, section reorder, rewording of core lines, whitespace churn
4. Adopt: apply reviewed core changes inside the marker range, keep the byte-stability contract, add a CHANGELOG entry citing the upstream commit, retag vN-upstream AT THE UPSTREAM FETCH COMMIT (never at a fork commit - fork commits carry the marker wrapper), and bump the pinned ref consumers use (`.githooks/baseline.sh`: tag name + SHA together). A core-change commit is the deliberate sync signal: it stages SYNC.md carrying an `Upstream-Commit: <40-hex-sha>` line naming the adopted upstream commit, and the commit message carries the same trailer. The hooks VERIFY the signal, not just its format: the SHA must resolve and be reachable from upstream/main (upstream is fetched; an unreachable fetch fails closed), the proposed core must equal that commit's AGENTS.md byte-exactly, and `.githooks/baseline.sh` PINNED_SHA must be bumped to that SHA in the same change. A whitespace-only SYNC.md edit is not a sync signal (hooks reject it)
5. If upstream wakes after long dormancy: re-review this protocol before merging anything

## Enforcement status (exact, as of 2026-11-24)

ON right now:

- CI workflow `.github/workflows/verify.yml` runs on every PR and on pushes to main: marker pair check, core byte-stability against the PINNED baseline via `.githooks/baseline.sh` (fails closed on missing, moved, or rogue `v*-upstream` tags - the newest tag is never trusted), betterleaks installed at a pinned version with a sha256-verified checksum (fail closed on download or checksum failure), a pattern layer that always runs, a PII layer (machine-local paths, private LAN addresses), and every `.githooks/*control*` reject-path driver. Because the workflow itself comes from the PR branch, its rules are only as strong as the review of changes to it
- Branch protection on main is a 0-approval required-PR gate with `enforce_admins=false`: it is NOT review and NOT core enforcement. It blocks force-push and deletion; admins retain bypass
- Hooks are clone-local: contributors must run `git config core.hooksPath .githooks`, and `--no-verify` bypasses them entirely; web-UI PR merges bypass them
- Routine pushes should use a non-admin token so the force-push block binds writers; admin pushes are for reviewed syncs only

WAITING ON THE OWNER (see [SETUP.md](./SETUP.md) for the exact settings steps):

- Required status check `verify` on main (until then, a web-UI merge can skip CI entirely)
- Required code-owner review for the enforcement paths via [CODEOWNERS](./CODEOWNERS) (until then, a PR can rewrite `.github/`, `.githooks/`, `AGENTS.md`, or `SYNC.md` - the gates included - without an owners review)

## Repository hooks

- Enable: `git config core.hooksPath .githooks`
- `pre-commit`: whitespace check; secret scan fail-fast in layers - betterleaks (`betterleaks git --pre-commit --staged`) when installed, plus a pattern scan that always runs (entropy-gated scanner rules do not see low-entropy synthetic keys), plus a PII layer rejecting machine-local paths and private LAN addresses; marker-pair check (staged removal of AGENTS.md is rejected outright as "AGENTS.md removed"); protected-core integrity compared byte-exactly with `cmp` (trailing newlines count). Core edits are blocked unless SYNC.md is staged AND passes `.githooks/sync-check.sh`: the `Upstream-Commit: <40-hex-sha>` SHA must be reachable from upstream/main, the proposed core must equal that commit's AGENTS.md byte-exactly, and `baseline.sh` PINNED_SHA must be bumped to it in the same change - a whitespace-only SYNC.md edit or a format-only trailer unlocks nothing
- `pre-push`: marker pair uniqueness + core byte-stability against the PINNED baseline via `.githooks/baseline.sh`, compared byte-exactly with `cmp`; fails closed on unreadable ranges, on missing/moved/rogue `v*-upstream` tags (the newest tag is never trusted), on a tip with no AGENTS.md, and on a diverged core whose sync signal fails the same verification as pre-commit
- `sync-check.sh`: shared verifier for the reviewed sync path (reachability from upstream/main, core equality, pin bump), used by both hooks
- Test drivers (negative and positive controls): `negative-control-secret.sh`, `negative-control-core.sh`, `negative-control-push.sh`, `negative-control-baseline-missing.sh`, `negative-control-rogue-tag.sh`, `negative-control-trailing-newline.sh`, `negative-control-whitespace-unlock.sh`, `negative-control-pii.sh`, `negative-control-delete.sh`, `negative-control-sync-fake-sha.sh`, `negative-control-sync-nopin.sh`, `positive-control-clean.sh`, `positive-control-push.sh`, `positive-control-sync.sh`, `positive-control-install.sh`. CI (`.github/workflows/verify.yml`) runs every `*control*.sh` driver on each PR; rejection-reason assertions pin the controls to the intended gate

## Reject conditions (hard)

- Any edit inside the DOX-CORE marker range that is not a reviewed upstream core change
- Promotion of addenda into the canonical `AGENTS.md`
- Reformat or reorder of core sections
- Unreviewed merges from upstream that touch `AGENTS.md`
