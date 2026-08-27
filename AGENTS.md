# Project Agent Rules & Development Guidelines

## Project Overview

`Raspberry-Pi-OS-Bing-Wallpaper-Auto-update` is a Bash automation utility that downloads
the daily Bing wallpaper and sets it as the desktop background on **Raspberry Pi OS**
(Wayfire / Labwc) and **Xubuntu** (XFCE). It ships as three POSIX-adjacent Bash scripts,
installed via cron for unattended daily updates.

Primary product scripts (Bash, run as the desktop user):

- `bing_wallpaper.sh` — fetch the Bing image-of-the-day, name it, save it, and set it as
  wallpaper for the detected desktop environment (XFCE / Wayfire / Labwc)
- `install.sh` — interactive installer: download/copy the script, prompt for region,
  resolution, and cron schedule, write the crontab entry, run once
- `uninstall.sh` — remove the installed script, log file, and crontab entry

Local/CI tooling is Bash + Python around a Dockerized `bats` + `kcov` suite:

- `scripts/quality_checks.sh` — formatters, linters, and the line-length policy
- `tests/run_suite.sh` — in-container `bats` suites, optionally wrapped in `kcov`
- `tests/transform_coverage.py` / `tests/generate_summary.py` — Cobertura XML →
  coverage badge (`assets/coverage.svg`) and PR summary
- `scripts/local/*.ps1` — Windows host orchestration (build image, quality, tests,
  coverage) mirroring `.github/workflows/ci.yml`

Human docs live under `README.md` and `docs/`. Agent guidance lives in this file and
under `.agents/skills/`, with Copilot-oriented mirrors under `.github/`.

## Agent Surface Map

| Path | Role |
| --- | --- |
| `AGENTS.md` | Canonical project rules for any coding agent (this file) |
| `.agents/skills/*/SKILL.md` | Task skills (quality, tests, install/uninstall, coverage) |
| `.agent/ai_rules.md` | Short AI-agnostic pointer into this file |
| `.agent/workflows/*.md` | Step-by-step workflows for common agent tasks |
| `CLAUDE.md` | Thin entrypoint for Claude Code (auto-loaded) |
| `GEMINI.md` | Thin entrypoint for Gemini CLI (auto-loaded) |
| `.github/agents/*.agent.md` | Copilot specialist personas |
| `.github/skills/*/SKILL.md` | Copilot skill mirrors (keep aligned with `.agents/skills`) |
| `.github/instructions/*.instructions.md` | Path-scoped Copilot instructions |
| `.github/prompts/*.prompt.md` | Invokable Copilot prompts |
| `.github/copilot-instructions.md` | Repo-wide Copilot baseline |
| `docs/Instructions.md` | Human/AI docs index into `docs/` |

On every task, update **this file** and all other relevant Markdown per **Always
Update Relevant Markdown** below. Keep `.github/` mirrors consistent when the
Copilot surface would otherwise drift.

## Code Style & Testing Enforcement

- **Mandatory order**: format/lint → tests → coverage (≥90%). Never skip a gate or
  reorder to hide failures.
- **No suppressions**: never add `# shellcheck disable`, `# noqa`, `# type: ignore`,
  markdownlint disables, or equivalent. Fix the root cause instead.
- **Line length**: non-Markdown source/config files ≤ **140** characters
  (`scripts/check_line_length.py`). Markdown line length is intentionally not
  enforced; wrap for readability anyway.
- **Shell formatting**: `shfmt -i 2 -ci` on `bing_wallpaper.sh`, `install.sh`,
  `uninstall.sh`, `tests/*.sh`.
- **Shell lint**: `shellcheck -x -S style` on the same files.
- **Python tooling** (`tests/*.py`, `scripts/*.py`): `ruff format --check`,
  `ruff check`, `mypy` (strict, see `pyproject.toml`, line-length 140).
- **YAML**: `yamllint` over the workflow and lint-config files.
- **Dockerfile**: `hadolint`.
- **Markdown**: `markdownlint-cli2` over agent/docs Markdown.
- **Failure handling**: do not hide, suppress, or downgrade real failures. The
  wallpaper, install, and uninstall scripts must report real errors and exit
  nonzero on failure.
- **Coverage**: merged `kcov` Cobertura total ≥ **90%**. Local runners refresh
  `assets/coverage.svg` via `tests/transform_coverage.py`. CI validates coverage
  but does not commit the badge — regenerate it locally before shipping
  coverage-affecting changes.

Local entrypoints:

```bash
./scripts/quality_checks.sh          # requires the tool versions pinned in Dockerfile
docker build -t wallpaper-test .
docker run --rm -v "$PWD:/workdir" -w /workdir wallpaper-test bash scripts/quality_checks.sh
docker run --rm --security-opt seccomp=unconfined --cap-add SYS_PTRACE \
  -e COVERAGE=1 -e COVERAGE_OUTPUT=/app/coverage -v "$PWD/coverage:/app/coverage" \
  wallpaper-test ./tests/run_suite.sh
```

Windows / full host orchestration:

```powershell
./scripts/local/run_quality_local.ps1
./scripts/local/run_tests_local.ps1
./scripts/local/run_coverage_local.ps1
```

## Directory Layout Reference

| Path | Purpose |
| --- | --- |
| `bing_wallpaper.sh` | Fetch, name, save, and apply the daily Bing wallpaper. |
| `install.sh` | Interactive installer: region/resolution prompts, cron wiring, first run. |
| `uninstall.sh` | Remove installed script, log, and crontab entry. |
| `Dockerfile` | Pinned Debian trixie-slim test image (bats, kcov, shellcheck, shfmt, ruff, mypy, yamllint, hadolint, markdownlint-cli2). |
| `tests/*.bats` | `bing_wallpaper_test.bats`, `install_test.bats`, `uninstall_test.bats`, `e2e_tests.bats`. |
| `tests/run_suite.sh` | bats runner; `--file`, `--installer-only`, `--maintenance-only/--component-only`, `--e2e-only`. Wraps in `kcov` when `COVERAGE=1`. |
| `tests/run_coverage.sh` | Single-shot local coverage run producing `coverage/cobertura.xml`. |
| `tests/transform_coverage.py` | Cobertura XML → `assets/coverage.svg` badge. |
| `tests/generate_summary.py` | Cobertura XML → Markdown coverage summary (CI PR comment / step summary). |
| `tests/mocks/` | Deterministic stand-ins for `curl`, `crontab`, `pcmanfm`, `pgrep`, `xfconf-query`, `xrandr`. |
| `scripts/quality_checks.sh` | Canonical quality gate; mirrors the CI `quality-gates` job. |
| `scripts/check_line_length.py` | Enforces the 140-char non-Markdown policy. |
| `scripts/local/*.ps1` | Windows-host quality/test/coverage orchestration (build image, run gates). |
| `assets/coverage.svg` | Locally generated coverage badge (commit after coverage-affecting changes). |
| `docs/Instructions.md` | Setup / build / contribute guide. |
| `docs/project_overview.md` | What this project does and why. |
| `docs/shell_scripts.md` | Behavior notes per shell script. |
| `docs/testing_coverage.md` | Testing and coverage conventions. |
| `docs/development_standards.md` | Style/testing/CI standards reference. |
| `docs/releases/vX.Y.Z.md` | Per-release notes; GitHub Release body source. Authored via the `prepare-release` skill. |
| `VERSION` | Single source of truth for the released semver (`vN.N.N`). Read by `.github/workflows/release.yml` to validate a pushed tag. |
| `.github/workflows/ci.yml` | GHA: `quality-gates` → `unit-tests` / `component-tests` / `system-tests` → `coverage-report` (merge + threshold + summary). |
| `.github/workflows/release.yml` | GHA: on `v*` tag push — validates `VERSION` matches the tag and `docs/releases/<tag>.md` exists, then creates the GitHub Release from those notes. |

## Dependency & Mocking Policy

- Prefer real tools in the test image (`curl`, `crontab`, desktop CLI shims) over
  inventing fake owned APIs.
- **Never mock the product scripts themselves** (`bing_wallpaper.sh`, `install.sh`,
  `uninstall.sh`). Tests must exercise the real scripts.
- Mock only external boundaries that cannot run safely/deterministically in CI: the
  live Bing HTTP API, `crontab`, and desktop-environment tools (`pcmanfm`, `pgrep`,
  `xfconf-query`, `xrandr`). Fixtures/stubs live under `tests/mocks/`.
- **Mocks must be cross-platform-safe to author**: avoid OS-specific paths unless
  conditional logic handles both; when mocking binaries, account for Windows vs.
  Linux differences (e.g. `.exe` suffixes) even though the mocks run inside the
  Linux test container — the local PowerShell runners execute the same repo on
  Windows hosts.
- Avoid network dependency in the bats suites; use `tests/mocks/curl` and fixed
  JSON payloads instead of live Bing calls.

## Non-Negotiable Constraints

- No suppressions, disables, or lint-ignore shortcuts in code.
- All quality checks must remain mandatory both locally and in CI.
- Preserve the 140-char limit for non-Markdown source/config files.
- Preserve the 90% minimum coverage gate.
- Preserve script behavior on Raspberry Pi OS (Wayfire/Labwc) and Xubuntu (XFCE)
  unless the task explicitly requests a behavior change.

## Always Update Relevant Markdown

**Every time you work in this repository**, update **all relevant Markdown files
in the same change set**. Do not finish a task with stale docs after code, CI,
test, workflow, or dependency changes.

Before completing work, audit what you changed and update every MD file that
would otherwise drift:

| Area | Paths |
| --- | --- |
| Canonical agent rules | `AGENTS.md` |
| Agent entrypoints | `CLAUDE.md`, `GEMINI.md`, `.agent/ai_rules.md`, `.agent/workflows/*.md` |
| Task skills | `.agents/skills/*/SKILL.md` |
| Copilot surface | `.github/copilot-instructions.md`, `.github/AGENTS.md`, `.github/skills/*/SKILL.md`, `.github/instructions/*.instructions.md`, `.github/agents/*.agent.md`, `.github/prompts/*.prompt.md` |
| Human docs | `README.md`, `docs/Instructions.md`, `docs/project_overview.md`, `docs/shell_scripts.md`, `docs/testing_coverage.md`, `docs/development_standards.md` |
| Releases | `docs/releases/vX.Y.Z.md` when cutting a release |

Rules:

- If a command, path, behavior, gate, or workflow changed, update every MD that
  references it — agent docs **and** human docs.
- Keep `.github/skills/` mirrors aligned with `.agents/skills/` when either side
  changes.
- Prefer one canonical body in `AGENTS.md`; adapters (`CLAUDE.md`, `GEMINI.md`,
  `.github/copilot-instructions.md`) stay short pointers with no divergent rule
  copies.
- Documentation-only tasks still require cross-file consistency for linked
  paths, commands, and version references.
