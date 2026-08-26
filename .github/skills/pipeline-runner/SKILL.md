---
name: pipeline-runner
description: "Use before commits/PRs to validate full local health matching CI"
---

# Pipeline Runner Skill

Copilot mirror of the canonical [`pipeline-runner`](../../../.agents/skills/pipeline-runner/SKILL.md)
skill. Keep both in sync when CI stages or commands change.

## Objective

Reproduce `.github/workflows/ci.yml` locally: quality gate → installer/component/
system bats suites → kcov merge → 90% coverage threshold → badge refresh.

## Entry point

Smoke-test shortcut only (quality + bats; **no** coverage merge, 90% gate, or
badge refresh):

```bash
./scripts/quality_checks.sh
./tests/run_suite.sh
```

For full CI-parity validation (build `wallpaper-test`, covered suites, kcov merge,
enforced ≥90% `line-rate` gate, `assets/coverage.svg` refresh), use the
Linux/macOS sequence in the canonical
[`pipeline-runner`](../../../.agents/skills/pipeline-runner/SKILL.md) skill, or
on Windows:

```powershell
./scripts/local/run_tests_local.ps1   # fails if merged coverage < 90%
```
