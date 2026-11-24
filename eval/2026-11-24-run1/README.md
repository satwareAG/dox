# Eval run 2026-11-24-run1

Single documented run. Raw artifacts in `runs/`, machine summary in `summary.json` (written by `../collect.mjs`). Fixed model: zai-coding-plan/glm-5.3-flash (subscription, cost 0 per run). Runner: opencode 2.4.1 CLI, one fresh fixture copy per run, `--archived` scripted sessions. Fixtures built by `../fixtures.sh`; success oracle `../check.sh`.

## Tasks (fixed prompts, identical across configs)

- t1: "In this project, change the API base path in src/config.js from /v1 to /v2. Then stop and report." - success criteria: config.js uses /v2, no /v1 left
- t2: "Release version 1.3.0 of this project: bump the version in package.json to 1.3.0 and add a matching release entry to docs/changelog.md (today is 2026-11-24). Then stop and report." - success criteria: package.json 1.3.0, changelog 1.3.0 entry

## Configs

| Config | AGENTS.md setup |
|--------|-----------------|
| fixture-no-dox | none |
| fixture-bare | single generic root AGENTS.md ("keep the docs in sync"), no DOX |
| fixture-dox | DOX template + honesty addendum, prebuilt two-child tree (docs/, src/ child docs; root Child DOX Index filled); child rules: config.js base-path changes sync docs/guide.md examples; release entries append src/version-ledger.md |

## Raw counts (primary success 6/6; turn = one user or assistant message; token fields from session records)

| Run | success | tokens in | tokens out | tool calls | turns | seconds |
|-----|---------|-----------|------------|------------|-------|---------|
| no-dox t1 | true | 35511 | 905 | 4 | 5 | 16 |
| bare t1 | true | 35716 | 905 | 4 | 5 | 27 |
| dox t1 | true | 43335 | 2919 | 8 | 6 | 36 |
| no-dox t2 | true | 70583 | 856 | 4 | 4 | 15 |
| bare t2 | true | 71101 | 1095 | 6 | 6 | 19 |
| dox t2 | true | 85888 | 3014 | 12 | 8 | 39 |

## Secondary observation (child-doc rules, not part of primary success)

| Run | guide.md synced to /v2 (t1 rule) | version-ledger.md appended (t2 rule) | AGENTS.md mentions in transcript |
|-----|----------------------------------|--------------------------------------|----------------------------------|
| no-dox t1/t2 | no | no | 12 / 4 |
| bare t1/t2 | no | no | 15 / 20 |
| dox t1/t2 | yes | yes (1 entry) | 124 / 102 |

## Reading

On this single run, both fixed tasks succeeded in all three configs while the DOX configs used more tokens (t1: 43335 vs 35511 input, t2: 85888 vs 70583) and more tool calls (8 and 12 vs 4), and only the DOX runs additionally honored the two child-doc contracts recorded in the fixture tree (guide.md endpoint sync and version-ledger append), so the measured cost of DOX in this run bought contract coverage the other configs did not produce; this is one run, one model (glm-5.3-flash), one trivial fixture project, a prebuilt DOX tree whose build cost is NOT included in these numbers, and output tokens dominated by reasoning accounting variance, so it supports no claim beyond "harness works and numbers are recorded".

## Known caveats

- n=1 per cell; no error/retry variance captured (all six runs clean, no tool errors observed)
- fixture is trivially small; token deltas will not transfer to real repositories
- primary success criteria are achievable in every config by design; the differentiator is the secondary contract work
- DOX tree construction (index fill, child docs) was done deterministically by the harness, not by the agent; a cold-start eval would need a separate setup-phase measurement
- transcript-based tool counts and turns use the opencode 2.4.1 export schema; token fields come from session records (cost is 0 because the provider is subscription-billed)
