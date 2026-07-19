# Development Standards

## Environment Setup

### Prerequisites

- **Docker Desktop** (for running tests)
- **PowerShell** (for local test scripts on Windows)
- **Git** (for version control)

### Local Development

1. Clone the repository
2. Ensure Docker is running
3. Run `./scripts/local/run_tests_local.ps1` to verify everything works

## Coding Standards

### Shell Script Guidelines

- **Shebang**: Always use `#!/bin/bash`
- **Shellcheck**: All scripts must pass ShellCheck with no warnings
- **Formatting**: All shell scripts must pass `shfmt -i 2 -ci`
- **Quoting**: Always quote variables (`"$VAR"` not `$VAR`)
- **Error Handling**: Use `set -e` at the top of scripts where appropriate
- **Functions**: Prefer functions over inline code for reusability
- **Comments**: Document non-obvious logic

### Quality Toolchain

- Shell: `shfmt`, `shellcheck`
- Python: `ruff format --check`, `ruff check`, `mypy`
- YAML: `yamllint`
- Dockerfile: `hadolint`
- Markdown: `markdownlint-cli2`
- Line-length policy: `python3 scripts/check_line_length.py` (140 max, non-Markdown)

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Scripts | `snake_case.sh` | `bing_wallpaper.sh` |
| Functions | `snake_case` | `download_image()` |
| Variables | `UPPER_SNAKE_CASE` | `$REGION`, `$KEEP_OLD` |
| Test files | `*_test.bats` | `install_test.bats` |

### Testing Standards

- **Coverage Target**: Minimum **90%** code coverage (mandatory)
- **Test Naming**: Use descriptive test names
- **Isolation**: Tests should not depend on each other
- **Mocking**: Use mock binaries for external dependencies

## Mandatory Requirements

### Before Every Commit

1. ✅ Run `./scripts/local/run_tests_local.ps1` and ensure all tests pass
2. ✅ Run `./scripts/local/run_quality_local.ps1` and ensure all checks pass
3. ✅ Verify coverage is **≥90%**
4. ✅ **Commit the updated coverage badge** (`assets/coverage.svg`)
5. ✅ Update `docs/Instructions.md`, `README.md`, or `docs/` files if making functional changes

### Badge Automation

The coverage badge is generated **locally** during test runs:

```text
scripts/local/run_tests_local.ps1 → transform_coverage.py → badge.svg → assets/coverage.svg
```

> ⚠️ **Always commit the badge with your code changes.**
> CI does **not** update the badge—you must do this locally.

### Documentation Updates

When making changes, update the relevant documentation:

| Change Type | Update These Files |
|-------------|-------------------|
| New feature | `README.md`, `docs/shell_scripts.md` |
| Config change | `README.md`, `docs/shell_scripts.md` |
| Test change | `docs/testing_coverage.md` |
| Build/CI change | `docs/development_standards.md` |

## CI Pipeline

The GitHub Actions CI pipeline (`.github/workflows/ci.yml`) runs:

1. **Quality Gates**: Mandatory lint/format/type/line-length checks
2. **Unit Tests**: Install/uninstall test suites
3. **Component Tests**: Wallpaper script tests
4. **System Tests**: End-to-end integration tests
5. **Coverage Report**: Merged report with 90% minimum threshold

### CI Coverage Enforcement

The CI pipeline will **fail** if:

- Coverage drops below **90%**
- Any test suite fails
- Any quality gate fails

The badge is **not** updated by CI—you must generate and commit it locally.
