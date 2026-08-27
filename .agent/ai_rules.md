# AI Agent Instructions

Canonical project rules live in the repository root [`AGENTS.md`](../AGENTS.md).
Task skills live under [`.agents/skills/`](../.agents/skills/).

These short instructions apply to any automated coding assistant working here.

## 1. Quality Assurance Workflow

### Priority Order

1. **Lint First, Test Second**: resolve `shfmt` / `shellcheck` / `ruff` / `mypy` /
   `yamllint` / `hadolint` / `markdownlint-cli2` findings before chasing test
   failures.
2. **Single Pass**: address lint and test fixes in one coherent change when
   practical, but never reorder the sequence above to hide a failure.
3. **Coverage Verification**: total repository coverage must stay at **≥90%**
   (merged `kcov` Cobertura report).
4. **Badge Refresh**: after a covered test run, regenerate `assets/coverage.svg`
   via `tests/transform_coverage.py` and commit it alongside the change.

### Efficiency

- Prefer repository runners: `./scripts/quality_checks.sh` and
  `./tests/run_suite.sh` (or `./scripts/local/*.ps1` on Windows).
- See [`.agents/skills/`](../.agents/skills/) for full command sequences per task.

## 2. Cross-Platform Compatibility

- All mocks under `tests/mocks/` MUST be compatible with both Windows and Linux
  execution contexts (the PowerShell local runners execute this same repo on
  Windows hosts).
- Avoid OS-specific paths in mocks unless conditional logic handles both.
- When mocking binaries or system calls, account for platform differences (e.g.
  file extensions like `.exe` on Windows).

## 3. Always Update Relevant Markdown

On **every task**, update **all relevant Markdown files** in the same change set.
If you change commands, paths, behavior, gates, workflows, or dependencies,
update every agent doc and human doc that references them. See **Always Update
Relevant Markdown** in `AGENTS.md` for the full path list and rules.
