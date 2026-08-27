---
name: project-quality
description: "Use when adding, repairing, or validating project-wide lint, formatter, and CI quality enforcement"
---

# Project Quality Skill

Copilot mirror of the canonical [`quality-gate`](../../../.agents/skills/quality-gate/SKILL.md)
skill. Keep both in sync when commands or tools change.

## Objective

Maintain strict quality gates for Bash, Python, YAML, Dockerfile, Markdown, and line-length policy.

## Required Checks

1. Shell: `shfmt`, `shellcheck`.
2. Python: `ruff format --check`, `ruff check`, `mypy`.
3. YAML: `yamllint`.
4. Dockerfile: `hadolint`.
5. Markdown: `markdownlint-cli2`.
6. Repository line length: `python3 scripts/check_line_length.py`.

## Entry Point

Run `scripts/quality_checks.sh`.

## Completion Criteria

- All quality checks pass locally.
- CI quality job remains a hard prerequisite for test jobs.
- No new suppression patterns introduced.
