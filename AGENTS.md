# Agent Routing for This Project

## Default Agent

Use the default coding agent for most edits, and always preserve Bash behavior on Raspberry Pi OS and Xubuntu.

## Specialized Routes

- Shell runtime changes: prioritize `bing_wallpaper.sh`, `install.sh`, `uninstall.sh`, and shell tests.
- CI or tooling changes: prioritize `.github/workflows/ci.yml`, `Dockerfile`, and `scripts/quality_checks.sh`.
- Coverage tooling changes: prioritize `tests/transform_coverage.py` and `tests/generate_summary.py`.
- Documentation updates: keep `README.md`, `docs/Instructions.md`, and `docs/*.md` in sync.

## Non-Negotiable Constraints

- No suppressions, disables, or lint-ignore shortcuts in code.
- All quality checks must remain mandatory both locally and in CI.
- Preserve 140-char limit for non-Markdown source/config files.
- Preserve 90% minimum coverage gate.
