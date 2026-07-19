---
description: Apply lint and test fixes for a file in a single pass
---
# Fix Lint and Tests Workflow

This workflow guides the AI in fixing issues for a specific file or set of files, prioritizing code quality and coverage.

1. **Analyze & Fix Linting**
   - Run `./scripts/local/run_quality_local.ps1` first.
   - **Action**: Fix ALL formatter/lint/type issues before proceeding.
   - Required checks: `shfmt`, `shellcheck`, `ruff format --check`, `ruff check`, `mypy`, `yamllint`, `hadolint`, `markdownlint-cli2`, and 140-char non-Markdown line-length policy.

2. **Run Tests & Generate Badge**
   - Execute the local test runner script. This script runs tests, checks coverage, and generates the badge.

   ```powershell
   ./scripts/local/run_tests_local.ps1
   ```

   - **Action**: Monitor the output.
   - If tests fail: Fix code or mocks (ensure mocks are Windows/Linux compatible).
   - **Repeat** Step 1 if you modify code significantly.

3. **Verify Coverage**
   - Check the summary output from the test script.
   - **Requirement**: Total coverage must be **>= 90%**.
   - If < 90%: Add more tests to cover missing lines/branches.

4. **Confirm Badge Update**
   - Verify that `assets/coverage.svg` has been updated.
   - You must commit the updated badge along with your code changes.
