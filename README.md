<p align="center">
  <img src="./banner.jpg" alt="DOX" width="100%">
</p>

## How DOX works

DOX is a tiny AGENTS.md framework that gives an AI agent precise project context.

The agent keeps a hierarchy of AGENTS.md files as the project changes:

- root AGENTS.md contains project-wide instructions and the top-level index
- child AGENTS.md files contain local instructions for specific areas
- before any edit, the agent walks the docs tree from the root to the area it will touch
- the relevant docs give it exact local guidelines, so it does not edit blindly
- after meaningful changes, it updates the affected AGENTS.md files

The result is simple: traverse the docs, understand the local rules, make precise edits, keep the docs current. Less guessing. Less drift. Less "why did it touch that file?"

<p align="center">
  <a href="https://youtu.be/NVkRkioBXQc">
    <img src="./video-thumbnail.jpg" alt="Watch: One markdown file just fixed AI coding forever." width="640">
  </a>
</p>

## How to use

1. Run the installer from a checkout (or release bundle) of this repo:

   ```sh
   sh install.sh /path/to/your-project
   ```

   The installer installs the template `AGENTS.md` and appends [addenda/honesty.md](./addenda/honesty.md) after the closing core marker. Honesty is mandatory in every install. Optional flags: `--site-release` (for projects publishing live pages), `--lazy-read` (token-budgeted AGENTS.md chain reads; keeps reads to the chain owning the touched paths and requires explicit tool reads of nested files). Re-runs are idempotent.

2. No installer available? Append the contents of [addenda/honesty.md](./addenda/honesty.md) to your project's `AGENTS.md` after the closing `DOX-CORE-END` marker. **Copying AGENTS.md alone is incomplete**: without the honesty addendum the install is out of spec.

<br>
No runtime, no package, no dependencies - DOX is Markdown plus a small install script.

It works with any AI agent that supports AGENTS.md files, including Codex, Claude Code, OpenCode, and similar tools.

No AGENTS.md yet? Run the installer and it will place the file. The agent will see these instructions and will start building the DOX tree.

For an existing project, tell your agent: `Initialize DOX tree for this project now.` It will create all the child AGENTS.md files and indexes.

## Fork status

This is the satwareAG-maintained fork of [agent0ai/dox](https://github.com/agent0ai/dox), pinned at upstream commit 765ae4ac (tag `v0-upstream`). Upstream is dormant since 2026-09-01; this fork carries the maintained spec, the upstream sync protocol ([SYNC.md](./SYNC.md)), and installer-consumable addenda ([addenda/](./addenda/)). Core changes land only as reviewed upstream syncs - see SYNC.md for the protocol and reject conditions.

## Credits

<p align="center">
  Created by <strong><a href="https://www.agent-zero.ai/">Agent Zero</a></strong><br>
  Open-source agentic AI framework<br>
  <a href="https://www.agent-zero.ai/">Website</a> · <a href="https://github.com/agent0ai/agent-zero">GitHub repository</a>
</p>
