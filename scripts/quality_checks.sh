#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "[quality] Shell formatting check"
shfmt -d -i 2 -ci \
  bing_wallpaper.sh \
  install.sh \
  uninstall.sh \
  tests/*.sh

echo "[quality] Shell lint"
shellcheck -x -S style \
  bing_wallpaper.sh \
  install.sh \
  uninstall.sh \
  tests/*.sh

echo "[quality] Python format check"
ruff format --check tests/*.py scripts/*.py

echo "[quality] Python lint"
ruff check tests/*.py scripts/*.py

echo "[quality] Python type check"
mypy tests/*.py scripts/*.py

echo "[quality] YAML lint"
yamllint \
  .github/workflows/ci.yml \
  .hadolint.yaml \
  .markdownlint.yaml \
  .pre-commit-config.yaml \
  .yamllint.yaml

echo "[quality] Dockerfile lint"
hadolint Dockerfile

echo "[quality] Markdown lint"
markdownlint-cli2 \
  "AGENTS.md" \
  "CLAUDE.md" \
  "GEMINI.md" \
  ".instructions.md" \
  ".prompt.md" \
  "README.md" \
  "docs/Instructions.md" \
  "docs/**/*.md" \
  ".github/**/*.md" \
  ".agent/**/*.md" \
  ".agents/**/*.md"

echo "[quality] Line-length policy"
python3 scripts/check_line_length.py

echo "[quality] All checks passed"
