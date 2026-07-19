# Testing & Coverage

## Testing Framework

This project uses [BATS](https://github.com/bats-core/bats-core) (Bash Automated Testing System) for shell script testing, with [kcov](https://github.com/SimonKagwortz/kcov) for code coverage.

### Test Suites

| File | Description |
|------|-------------|
| `tests/install_test.bats` | Unit tests for `install.sh` |
| `tests/uninstall_test.bats` | Unit tests for `uninstall.sh` |
| `tests/bing_wallpaper_test.bats` | Component tests for `bing_wallpaper.sh` |
| `tests/e2e_tests.bats` | End-to-end integration tests |

### Running Tests Locally

Tests run inside Docker for consistency. Use the PowerShell script:

```powershell
./scripts/local/run_tests_local.ps1
```

Run mandatory quality checks first:

```powershell
./scripts/local/run_quality_local.ps1
```

This script:

1. Builds the Docker test image
2. Runs all test suites with coverage
3. Merges coverage reports from all suites
4. Generates the coverage badge
5. Outputs a coverage summary

### Coverage Requirements

> ⚠️ **MANDATORY: 90% minimum code coverage is required.**

The CI pipeline will **fail** if coverage drops below 90%. This threshold is enforced in:

- `.github/workflows/ci.yml` (explicit threshold check: `>= 90%`)
- Local test runs will generate a warning if below 90%

### Coverage Badge Generation

**Important:** The coverage badge (`assets/coverage.svg`) is generated **locally**, not by CI.

After running tests locally, the badge is automatically updated by `tests/transform_coverage.py`. You **must** commit the updated badge before pushing.

#### Badge Generation Process

1. `scripts/local/run_tests_local.ps1` runs all tests with kcov
2. Coverage reports are merged into `coverage/cobertura.xml`
3. `transform_coverage.py` processes the XML and generates `badge.svg`
4. The badge is moved to `assets/coverage.svg`
5. **You must commit the badge** with your changes

#### Manual Badge Generation

If you only want to regenerate the badge from existing coverage:

```powershell
docker run --rm -v "${PWD}:/workdir" -w /workdir wallpaper-test python3 tests/transform_coverage.py coverage/cobertura.xml
# Then move badge.svg to assets/coverage.svg
```

### Mock Binaries

The `tests/mocks/` directory contains mock implementations of system binaries used during testing:

- Mock `pcmanfm` for wallpaper setting
- Mock `curl` for network requests
- Mock `crontab` for schedule management
