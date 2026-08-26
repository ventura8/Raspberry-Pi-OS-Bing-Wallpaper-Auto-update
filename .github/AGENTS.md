# AGENTS

Canonical rules: [`../AGENTS.md`](../AGENTS.md)

Project skills: [`.agents/skills/`](../.agents/skills/) (mirrored under
`.github/skills/` for Copilot).

## Available Specialist Modes

### Quality Guardian

Use when asking for lint, formatter, or CI quality-gate enforcement changes.
Skill: `project-quality` / `quality-gate`. Agent persona: `quality.agent.md`.

### Shell Runtime Maintainer

Use when changing `bing_wallpaper.sh`, `install.sh`, `uninstall.sh`, or cron
behavior. Skill: `installer-tester` for install/uninstall-focused changes.

### Coverage & Badge Engineer

Use when merged coverage, `assets/coverage.svg`, or the Cobertura pipeline is
affected. Skill: `coverage-workflow` / `coverage-badge`.

### Pipeline Runner

Use when validating full local health before a PR. Skill: `pipeline-runner`.

### Prepare Release

Use when bumping the version everywhere and writing release notes. Skill:
`prepare-release`. Never tags, pushes, or runs `gh release create` unless
explicitly asked — tagging alone triggers `.github/workflows/release.yml`.

## Shared Rules

- Preserve reproducible, pinned tool versions (see `Dockerfile`).
- Keep non-Markdown line length at 140 or fewer characters.
- Do not add lint suppression directives.
- Keep CI and local checks aligned.
- On **every task**, update **all relevant Markdown files** in the same change set
  (see **Always Update Relevant Markdown** in [`../AGENTS.md`](../AGENTS.md)).
