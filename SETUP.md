# SETUP - repo settings only the owner can change (Michael)

The CI workflow and hooks in this repository run from the PR branch and are
enforced nowhere by default. These GitHub settings turn them into real gates.
All steps are owner actions in repo Settings; nothing in this repository can
enable them from a branch.

## 1. Make the verify check required on main

Settings > Branches > Add branch ruleset (or Branch protection rule) for `main`:

- Require a pull request before merging: ON
- Require status checks to pass: ON, add required check `verify`
  (the check name comes from `.github/workflows/verify.yml` `name: verify`;
  it must have run at least once on a PR before GitHub offers it in the list)
- Require branches to be up to date before merging: recommended ON
- Do NOT tick "Require approvals" count > 1 unless solo review should block;
  the code-owner review in step 2 provides the review requirement

## 2. Require code-owner review for the enforcement paths

Same ruleset (or a second one scoped to the enforcement paths):

- Require review from Code Owners: ON

With [CODEOWNERS](./CODEOWNERS) committed, any change to `.github/`,
`.githooks/`, `AGENTS.md`, `SYNC.md`, `SETUP.md`, or `install.sh` then needs
an owners-team review, so the verification machinery cannot be loosened
unchecked.

## 3. Recommended, not blocking

- Restrict who can push matching branches: leave default ( admins bypass by
  design; see SYNC.md enforcement honesty)
- Settings > Actions > General > Workflow permissions: "Read repository
  contents and packages permissions" (verify.yml already declares
  `permissions: contents: read`, the default here is belt and braces)

## What this changes in practice

| Threat | Covered by | Still open until |
|--------|------------|------------------|
| Hook bypass (`--no-verify`) on local commits | pre-push + CI on the PR | step 1 (required check) |
| Web-UI merge without CI | required status check | step 1 |
| Loosening the workflow/hooks themselves | CODEOWNERS + required review | step 2 |
| Force-push rewriting main | branch protection (already on: 0-approval required-PR gate blocks force-push) | - |

Until steps 1 and 2 are done, the gates exist only as CI-on-PR + clone-local
hooks; SYNC.md "Enforcement status" states exactly this.
