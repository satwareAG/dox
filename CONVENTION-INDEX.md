# CONVENTION-INDEX - machine-checkable Child DOX Index (opt-in)

Status: opt-in convention. A linter exists (`node tools/lint-convention-index.mjs <dir>`, self-test via `--selftest`) covering rules 1-5 with the fixture matrix below; it is not yet a CI merge gate. Enforcement triggers are listed at the bottom.

## Entry format

The Child DOX Index section of any AGENTS.md using this convention is a markdown table:

```text
| Path | Scope | File |
|------|-------|------|
| `X/` | one-line scope description | [AGENTS.md](X/AGENTS.md) |
```

Rules (machine-checkable):

1. Every `Path` ends with `/` and is relative to the owning AGENTS.md
2. Every `File` link resolves to an existing `AGENTS.md` in that path
3. `Scope` is a non-empty one-line description
4. Entries are unique by path (no duplicates)
5. A childless project with an empty or absent index is VALID - absence is not an error
6. Child docs follow the default section order: Purpose, Ownership, Local Contracts, Work Guidance, Verification, Child DOX Index

## CI gate triggers (any one - then build the linter and fixtures)

- A consumer tree drifts undetected twice (a stale entry hides instructions from agents)
- Upstream lands its own machine-checkable convention that can be adopted
- A real fixture tree exists in this repo to test against

Fixture matrix (implemented in the linter self-test): childless (valid), valid tree, stale entry (missing trailing slash), missing file, duplicate path.
