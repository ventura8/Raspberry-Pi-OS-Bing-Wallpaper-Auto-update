---
name: coverage-workflow
description: "Use when working on coverage merge, badge generation, or coverage threshold enforcement"
---

# Coverage Workflow Skill

## Objective

Keep coverage processing stable and enforce the 90% threshold in local and CI workflows.

## Key Files

- `tests/transform_coverage.py`
- `tests/generate_summary.py`
- `scripts/local/run_tests_local.ps1`
- `scripts/local/run_coverage_local.ps1`
- `.github/workflows/ci.yml`

## Rules

1. Preserve XML transformation compatibility with downstream summary generation.
2. Keep badge output path as `assets/coverage.svg`.
3. Ensure threshold checks fail below 90%.
4. Keep local and CI behavior aligned.
