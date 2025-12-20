#!/bin/bash
set -e

# Default settings
COVERAGE_OUTPUT="${COVERAGE_OUTPUT:-coverage}"
# If COVERAGE env is set, we wrap with kcov
USE_COVERAGE="${COVERAGE:-0}"

# Helper to run bats
run_bats() {
    local suite_name="$1"
    shift
    local tests=("$@")

    echo "=== Running Suite: $suite_name ==="
    
    if [ "$USE_COVERAGE" -eq 1 ]; then
        # Ensure output dir exists
        mkdir -p "$COVERAGE_OUTPUT/$suite_name"
        
        # We assume kcov is installed
        # running kcov for specific test files
        # kcov --include-path=. --exclude-path=tests <outdir> bats <files>
        
        # Note: kcov collects coverage per execution. 
        # If we pass multiple files to bats, bats runs them. 
        # kcov wraps the bats process.
        
        kcov \
            --include-path=. \
            --exclude-path=tests \
            --include-pattern=.sh \
            "$COVERAGE_OUTPUT/$suite_name" \
            bats "${tests[@]}"
    else
        bats "${tests[@]}"
    fi
}

MODE="all"

# Argument parsing
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --installer-only) MODE="installer" ;;
        --maintenance-only|--component-only) MODE="component" ;;
        --e2e-only) MODE="e2e" ;;
        --file) MODE="file"; FILE="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

echo "Starting Test Suite Runner (Mode: $MODE)..."

if [ "$MODE" == "file" ]; then
    if [ -z "$FILE" ]; then
        echo "Error: --file argument required for file mode"
        exit 1
    fi
     # Determine suite name from filename for coverage output
     SUITE_NAME=$(basename "$FILE" .bats)
     # Sanitize suite name
     SUITE_NAME=${SUITE_NAME//./_}
     run_bats "$SUITE_NAME" "$FILE"
elif [ "$MODE" == "installer" ] || [ "$MODE" == "all" ]; then
    run_bats "installer" "tests/install_test.bats" "tests/uninstall_test.bats"
fi

if [ "$MODE" == "component" ] || [ "$MODE" == "all" ]; then
    run_bats "component" "tests/bing_wallpaper_test.bats"
fi

# Determine if running E2E
if [ "$MODE" == "e2e" ] || [ "$MODE" == "all" ]; then
    # Only run if e2e test file exists
    if [ -f "tests/e2e_tests.bats" ]; then
        run_bats "system" "tests/e2e_tests.bats"
    else
        echo "No E2E tests found, skipping."
    fi
fi

echo "All requested suites completed."
