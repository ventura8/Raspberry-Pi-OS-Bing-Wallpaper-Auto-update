---
name: pipeline-runner
description: >-
  Run the full local pipeline matching CI: quality gate, all Dockerized bats
  suites, kcov merge, coverage threshold, and badge refresh. Use before
  commits/PRs or when validating end-to-end repo health.
---

# Pipeline Runner Skill

## Use when

- Pre-commit / pre-PR validation
- Reproducing the `.github/workflows/ci.yml` sequence locally
- Confirming quality + tests + coverage together after a broad change

## Hard rules

1. Order is mandatory: `quality-gates` → (`unit-tests`, `component-tests`,
   `system-tests` in any order) → `coverage-report` (merge + threshold + badge).
   Mirrors `.github/workflows/ci.yml` job dependencies.
2. Do not ship with a stale `assets/coverage.svg` after a coverage-affecting
   change.
3. Use the locally built image tag `wallpaper-test` (built from the repo root
   `Dockerfile`) — not an external registry pin.
4. Fix every failure in source; never suppress a linter or skip a stage to get a
   clean run.

## Workflow (Linux / macOS)

```bash
set -euo pipefail
mkdir -p coverage coverage_inputs/installer coverage_inputs/component coverage_inputs/system

docker build -t wallpaper-test .

# 1. Quality gate
docker run --rm -v "$PWD:/workdir" -w /workdir wallpaper-test bash scripts/quality_checks.sh

# 2. Suites (each writes kcov output into its own coverage_inputs/<suite> dir)
docker run --rm --security-opt seccomp=unconfined --cap-add SYS_PTRACE \
  -e COVERAGE=1 -e COVERAGE_OUTPUT=/app/coverage \
  -v "$PWD/coverage_inputs/installer:/app/coverage" \
  wallpaper-test ./tests/run_suite.sh --file tests/install_test.bats

docker run --rm --security-opt seccomp=unconfined --cap-add SYS_PTRACE \
  -e COVERAGE=1 -e COVERAGE_OUTPUT=/app/coverage \
  -v "$PWD/coverage_inputs/installer:/app/coverage" \
  wallpaper-test ./tests/run_suite.sh --file tests/uninstall_test.bats

docker run --rm --security-opt seccomp=unconfined --cap-add SYS_PTRACE \
  -e COVERAGE=1 -e COVERAGE_OUTPUT=/app/coverage \
  -v "$PWD/coverage_inputs/component:/app/coverage" \
  wallpaper-test ./tests/run_suite.sh --file tests/bing_wallpaper_test.bats

docker run --rm --security-opt seccomp=unconfined --cap-add SYS_PTRACE \
  -e COVERAGE=1 -e COVERAGE_OUTPUT=/app/coverage \
  -v "$PWD/coverage_inputs/system:/app/coverage" \
  wallpaper-test ./tests/run_suite.sh --e2e-only

# 3. Merge, threshold, badge, summary — see coverage-badge skill for details
mkdir -p coverage/merged
docker run --rm --security-opt seccomp=unconfined --cap-add SYS_PTRACE --user root \
  -v "$PWD:/workdir" -w /workdir wallpaper-test \
  kcov --merge coverage/merged \
    coverage_inputs/installer/* coverage_inputs/component/* coverage_inputs/system/*

merged_xml="$(find coverage/merged -name cobertura.xml | head -n 1)"
if [ ! -f "$merged_xml" ]; then
  echo "Merged cobertura.xml not found" >&2
  exit 1
fi
cp "$merged_xml" coverage/cobertura.xml

docker run --rm -v "$PWD:/workdir" -w /workdir wallpaper-test \
  python3 tests/transform_coverage.py coverage/cobertura.xml

docker run --rm -v "$PWD:/workdir" -w /workdir wallpaper-test \
  python3 tests/generate_summary.py coverage/cobertura.xml | tee coverage-summary.md
```

Delegate to [quality-gate](../quality-gate/SKILL.md), [test-runner](../test-runner/SKILL.md),
and [coverage-badge](../coverage-badge/SKILL.md) for troubleshooting each stage.

## Workflow (Windows host)

```powershell
./scripts/local/run_tests_local.ps1
```

That script builds `wallpaper-test`, runs the quality gate inside the image, runs
all three covered suites, merges kcov output, fails if merged Cobertura
`line-rate` is below 90%, refreshes `assets/coverage.svg`, and prints the
coverage summary.

## Done criteria

- Quality gate exit 0 (no suppressions added)
- All bats suites exit 0
- Merged repository coverage ≥90%
- `assets/coverage.svg` regenerated and committed when coverage changed
- Summary of failures fixed, with root causes, not workarounds
