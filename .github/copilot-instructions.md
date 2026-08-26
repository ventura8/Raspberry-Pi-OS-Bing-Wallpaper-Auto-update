# Copilot Instructions for This Repository

This repository is a Bash-first project for automatic Bing wallpaper updates on Raspberry Pi OS and Xubuntu.

Canonical agent rules live in [`AGENTS.md`](../AGENTS.md); specialist modes and
skills are indexed in [`AGENTS.md`](AGENTS.md) and [`skills/`](skills/). Treat
this file as a quick-reference summary, not a second rulebook.

## Mandatory Quality Rules

- Run quality checks before tests: `scripts/quality_checks.sh`.
- Never add lint suppressions or disable comments in source files.
- Enforce max line length 140 for all non-Markdown source/config files.
- Keep Markdown linting enabled, but do not enforce Markdown line-length limits.
- Keep local and CI checks aligned; do not add checks in one without the other.
- Maintain coverage threshold at 90% or higher.

## Always Update Relevant Markdown

On **every task**, update **all relevant Markdown files** in the same change set.
See **Always Update Relevant Markdown** in [`AGENTS.md`](../AGENTS.md) for the
full path list (agent docs, Copilot mirrors, `README.md`, and `docs/*.md`).

## Primary Commands

- Local quality checks: `./scripts/local/run_quality_local.ps1`
- Local full pipeline: `./scripts/local/run_tests_local.ps1`
- Local coverage flow: `./scripts/local/run_coverage_local.ps1`

## Critical Files

- `bing_wallpaper.sh`: Main runtime behavior.
- `install.sh`: Installer and cron wiring.
- `uninstall.sh`: Uninstall and cleanup path.
- `tests/*.bats`: Test suites.
- `tests/transform_coverage.py`, `tests/generate_summary.py`: Coverage processing.
- `.github/workflows/ci.yml`: Mandatory CI gates.
