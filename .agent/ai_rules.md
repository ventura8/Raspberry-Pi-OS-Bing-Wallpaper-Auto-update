# AI Development Rules

## 1. Quality & Sequence

- **Lint First, Test Second**: When fixing issues in a file, ALWAYS resolve linting errors (`shfmt`, `shellcheck`, `ruff`, `mypy`, `yamllint`, `hadolint`, `markdownlint-cli2`) before attempting to fix test failures.
- **Single Pass**: Try to address both linting and testing issues in a coherent workflow, but strictly follow the sequence.
- **No Suppressions**: Do not add disable/ignore/suppress comments in source code.
- **Line Length**: Keep non-Markdown source/config lines at 140 chars or fewer.

## 2. Testing & Coverage

- **Mandatory 90% Coverage**: The codebase must maintain at least 90% test coverage.
- **Badge Generation**: AFTER running tests, you MUST regenerate the coverage badge locally using the provided scripts.
- **Check Coverage**: Verify that the generated coverage meets the 90% threshold.

## 3. Cross-Platform Compatibility

- **Mocks**: All mocks MUST be compatible with both Windows and Linux.
  - Avoid OS-specific paths in mocks unless conditional logic handles both.
  - Use `os.path.join` or `pathlib` for paths.
  - When mocking binaries or system calls, ensure the mock behaves correctly on both OSes (e.g., file extensions like `.exe` on Windows).
