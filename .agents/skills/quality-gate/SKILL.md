---
name: quality-gate
description: >-
  Run and enforce repository quality gates: shfmt, shellcheck, ruff, mypy,
  yamllint, hadolint, markdownlint-cli2, and the 140-char line-length policy via
  scripts/quality_checks.sh. Use when linting, formatting, fixing CI quality
  failures, or verifying local/CI parity.
---

# Quality Gate Skill

## Use when

- User asks to lint, format, or enforce standards
- The CI `quality-gates` job fails
- Verifying local checks match `.github/workflows/ci.yml`

## Hard rules

1. Fix root causes; never add `# shellcheck disable`, `# noqa`, `# type: ignore`,
   markdownlint disables, or equivalent suppressions ([AGENTS.md](../../../AGENTS.md)).
2. Non-Markdown source/config files stay ≤140 columns
   (`scripts/check_line_length.py`).
3. When fixing a file locally, format first (`shfmt -w`, `ruff format`), then lint in
   this order: `shellcheck`, `ruff check`, `mypy`, `yamllint`, `hadolint`,
   `markdownlint-cli2`, then `scripts/check_line_length.py`.
4. Auto-fix first when safe (`shfmt -w`, `ruff format`, `ruff check --fix`,
   `markdownlint-cli2 --fix`), then re-run the gate to confirm.
5. Prefer `scripts/quality_checks.sh` over one-off tool invocations — it is the
   single source of truth also used by CI's `quality-gates` job.

## Workflow

Requires the pinned tool versions from `Dockerfile` (shfmt, shellcheck, ruff,
mypy, yamllint, hadolint, markdownlint-cli2). Easiest via the test image:

```bash
docker build -t wallpaper-test .
docker run --rm -v "$PWD:/workdir" -w /workdir wallpaper-test bash scripts/quality_checks.sh
```

If the tools are already installed on the host:

```bash
./scripts/quality_checks.sh
```

`scripts/quality_checks.sh` runs the full verification gate (check mode, not
auto-fix) in this order: `shfmt -d`, `shellcheck -x -S style`,
`ruff format --check`, `ruff check`, `mypy`, `yamllint`, `hadolint`,
`markdownlint-cli2`, then `scripts/check_line_length.py`. Apply local
format/lint fixes per rule 3 above before re-running the gate.

Fix every reported failure in source, re-run until clean, then summarize the
files changed and why.
