#!/bin/bash
set -e

# Directory to store coverage results
COVERAGE_DIR="coverage"

# Clean previous coverage
# Only remove contents, not the directory itself, to avoid issues with volume mounts
rm -rf "${COVERAGE_DIR:?}"/*
mkdir -p "$COVERAGE_DIR"

# Run tests with kcov
# We include the source files we want coverage for
# We exclude the tests/ directory from coverage (although kcov might handle this if we point it to the source)
# --include-path=. tells kcov to only instrument files in the current dir (recursively)
# --exclude-path=tests excludes the tests themselves

echo "Running tests with kcov..."

kcov \
  --include-path=. \
  --exclude-path=tests \
  "$COVERAGE_DIR" \
  bats "${1:-tests/}"

# Move the cobertura report to the root of the coverage directory so it's easy to find
# Move the cobertura report to the root of the coverage directory so it's easy to find
echo "Searching for cobertura.xml..."
find "$COVERAGE_DIR" -name cobertura.xml -exec cp {} "$COVERAGE_DIR/cobertura.xml" \;

if [ ! -f "$COVERAGE_DIR/cobertura.xml" ]; then
    echo "FAILED to move cobertura.xml"
    exit 1
fi

echo "Coverage report generated in $COVERAGE_DIR"
