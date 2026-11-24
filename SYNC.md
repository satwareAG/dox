# SYNC - upstream sync protocol

- Upstream: https://github.com/agent0ai/dox (dormant since 2026-09-01)
- Baseline: tag `v0-upstream` pinned at commit 765ae4ac
- The canonical `AGENTS.md` core between the `DOX-CORE-START` and `DOX-CORE-END` markers stays byte-identical to `v0-upstream` except by an explicit, reviewed core upgrade

## Protocol

1. Fetch upstream: `git fetch upstream && git log --oneline v0-upstream..upstream/main`
2. Review core diffs only: `git diff v0-upstream upstream/main -- AGENTS.md`
3. Reject: reformatting, section reorder, rewording of core lines, whitespace churn
4. Adopt: apply reviewed core changes inside the marker range, keep the byte-stability contract, add a CHANGELOG entry citing the upstream commit, retag vN-upstream AT THE UPSTREAM FETCH COMMIT (never at a fork commit - fork commits carry the marker wrapper), and bump the pinned ref consumers use. A core-change commit stages SYNC.md as the deliberate sync signal and names the upstream commit
5. If upstream wakes after long dormancy: re-review this protocol before merging anything

## Enforcement status (read before relying on the hooks)

- Branch protection on main is a 0-approval required-PR gate with `enforce_admins=false`: it is NOT review and NOT core enforcement. It blocks force-push and deletion; admins retain bypass
- Hooks are clone-local: contributors must run `git config core.hooksPath .githooks`, and `--no-verify` bypasses them entirely; web-UI PR merges bypass them
- No server-side core or secret verification exists yet (docs-only fork, no CI). Follow-up: lightweight CI workflow on PRs (core integrity + betterleaks); open it before the first enforcement bypass, not after
- Routine pushes should use a non-admin token so the force-push block binds writers; admin pushes are for reviewed syncs only

## Repository hooks

- Enable: `git config core.hooksPath .githooks`
- `pre-commit`: whitespace check, secret scan fail-fast via betterleaks (`betterleaks git --pre-commit --staged`; pattern-scan fallback when betterleaks is absent), marker-pair check, protected-core integrity (core edits blocked unless SYNC.md is staged - the deliberate sync signal, naming the upstream commit)
- `pre-push`: marker pair uniqueness + core byte-stability against the latest `v*-upstream` tag, for every pushed ref touching AGENTS.md; fails closed on unreadable ranges
- Test drivers (negative and positive controls): `negative-control-secret.sh`, `negative-control-core.sh`, `negative-control-push.sh`, `positive-control-clean.sh`, `positive-control-push.sh`

## Reject conditions (hard)

- Any edit inside the DOX-CORE marker range that is not a reviewed upstream core change
- Promotion of addenda into the canonical `AGENTS.md`
- Reformat or reorder of core sections
- Unreviewed merges from upstream that touch `AGENTS.md`
