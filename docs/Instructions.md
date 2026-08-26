# AI Instructions: Bing Wallpaper for Raspberry Pi

This document provides technical guidance for AI agents and developers working on this project.

The detailed documentation has been split into multiple files for easier navigation and modularity.

## Documentation Index

- [Project Overview & Directory Structure](project_overview.md)
  - General project goals and file organization.
- [Shell Scripts & Logic](shell_scripts.md)
  - Detailed explanation of the main scripts (`bing_wallpaper.sh`, `install.sh`, `uninstall.sh`).
- [Testing & Coverage](testing_coverage.md)
  - Testing framework, coverage requirements, and badge generation.
- [Development Standards](development_standards.md)
  - Environment setup, coding standards, and mandatory requirements.
- [Release notes](releases/v1.0.2.md) (prior: [v1.0.1](releases/v1.0.1.md))
  - GitHub-ready release descriptions and release notes.
- [AI Rules](../.agent/ai_rules.md)
  - **For AI Agents**: Lint/test priority, coverage requirements, cross-platform
    compatibility, and the rule to update all relevant Markdown on every task
    (see [AGENTS.md](../AGENTS.md)).

## Mandatory Local Commands

- `./scripts/local/run_quality_local.ps1` must pass before tests.
- `./scripts/local/run_tests_local.ps1` runs the full local pipeline.
- `./scripts/local/run_coverage_local.ps1` runs the coverage-focused flow.

## Copilot Customization Files

- `../.github/copilot-instructions.md`
- `../AGENTS.md`
- `../.github/instructions/*.instructions.md`
- `../.github/prompts/*.prompt.md`
- `../.github/agents/*.agent.md`
- `../.github/skills/*/SKILL.md`
