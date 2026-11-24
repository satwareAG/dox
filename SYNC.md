# SYNC - upstream sync protocol

- Upstream: https://github.com/agent0ai/dox (dormant since 2026-09-01)
- Baseline: tag `v0-upstream` pinned at commit 765ae4ac
- The canonical `AGENTS.md` core between the `DOX-CORE-START` and `DOX-CORE-END` markers stays byte-identical to `v0-upstream` except by an explicit, reviewed core upgrade

## Protocol

1. Fetch upstream: `git fetch upstream && git log --oneline v0-upstream..upstream/main`
2. Review core diffs only: `git diff v0-upstream upstream/main -- AGENTS.md`
3. Reject: reformatting, section reorder, rewording of core lines, whitespace churn
4. Adopt: apply reviewed core changes inside the marker range, keep the byte-stability contract, add a CHANGELOG entry, retag (next `vN-upstream` tag), and bump the pinned ref consumers use
5. If upstream wakes after long dormancy: re-review this protocol before merging anything

## Reject conditions (hard)

- Any edit inside the DOX-CORE marker range that is not a reviewed upstream core change
- Promotion of addenda into the canonical `AGENTS.md`
- Reformat or reorder of core sections
- Unreviewed merges from upstream that touch `AGENTS.md`
