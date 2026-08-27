---
name: test-runner
description: >-
  Run the bats suites (installer, component, system/e2e) for this repo the way
  CI gates them, with or without kcov coverage, via tests/run_suite.sh. Use for
  unit/component/e2e checks on bing_wallpaper.sh, install.sh, and uninstall.sh.
---

# Test Runner Skill

When adding or changing code, run applicable tests in the same change set
([AGENTS.md](../../../AGENTS.md)).

## Suite layout

| Suite | File | CI job |
| --- | --- | --- |
| Installer | `tests/install_test.bats`, `tests/uninstall_test.bats` | `unit-tests` |
| Component | `tests/bing_wallpaper_test.bats` | `component-tests` |
| System / E2E | `tests/e2e_tests.bats` | `system-tests` |

All suites run inside the `wallpaper-test` Docker image (built from the repo
`Dockerfile`) so `bats`, `kcov`, and mocked binaries (`tests/mocks/`) are
available and deterministic.

## Run one suite (no coverage)

```bash
docker build -t wallpaper-test .
docker run --rm wallpaper-test ./tests/run_suite.sh --file tests/bing_wallpaper_test.bats
```

`tests/run_suite.sh` also accepts `--installer-only`, `--maintenance-only` /
`--component-only`, and `--e2e-only` (default: run everything).

## Run with kcov coverage (matches CI)

```bash
mkdir -p coverage
docker run --rm \
  --security-opt seccomp=unconfined \
  --cap-add SYS_PTRACE \
  -e COVERAGE=1 \
  -e COVERAGE_OUTPUT=/app/coverage \
  -v "$PWD/coverage:/app/coverage" \
  wallpaper-test ./tests/run_suite.sh --file tests/install_test.bats
```

`--security-opt seccomp=unconfined` and `--cap-add SYS_PTRACE` are required for
`kcov`'s ptrace-based instrumentation.

## Mocking policy

Never mock `bing_wallpaper.sh`, `install.sh`, or `uninstall.sh` themselves —
tests must exercise the real scripts. Only external boundaries are mocked
(`tests/mocks/curl`, `crontab`, `pcmanfm`, `pgrep`, `xfconf-query`, `xrandr`);
keep additions cross-platform-safe per `AGENTS.md`.

## Full local pipeline (quality + all suites + coverage merge + badge)

See [pipeline-runner](../pipeline-runner/SKILL.md), or on Windows:

```powershell
./scripts/local/run_tests_local.ps1
```
