<!-- ADDENDUM-START: lazy-read (optional - apply only when the token budget of large AGENTS.md chains matters) -->

## Lazy Read (token budget)

Read only the AGENTS.md chain that owns the paths you touch; never dump whole-repository context:

| Rule | Detail |
|------|--------|
| Chain-only reads | Before editing, read the root AGENTS.md and then ONLY the AGENTS.md files on the walk from root to each touched path (the Child DOX Index drives the walk). Do not read sibling branches of the tree |
| One-line index entries | Keep every Child DOX Index entry to one line: path, one-line scope, file link. No repository overviews inside index entries |
| No overviews in always-loaded files | AGENTS.md files are contracts, not status reports; keep repository summaries out of every file in the chain |
| Re-read only that chain | Re-read the same chain in the CURRENT session before editing; do not rely on memory and do not re-read unrelated chains |
| Explicit tool-read | Codex, OpenCode, Claude Code, and Cursor resolve nested AGENTS.md files differently; the walk MUST be an explicit tool read (file read of each AGENTS.md on the path), never an assumption that the runtime auto-loaded the chain |

<!-- ADDENDUM-END -->
