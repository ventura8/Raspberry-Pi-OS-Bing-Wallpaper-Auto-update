#!/usr/bin/env bats

setup() {
    # Get the project root directory
    PROJECT_ROOT="$( cd "$( dirname "$BATS_TEST_FILENAME" )/.." >/dev/null 2>&1 && pwd )"

    # Create a temporary directory for the test run
    TEST_DIR=$(mktemp -d)

    # Export HOME as the temp dir
    export HOME="$TEST_DIR"

    # Setup standard install paths
    mkdir -p "$HOME/scripts"
    touch "$HOME/scripts/bing_wallpaper.sh"
    touch "$HOME/scripts/wallpaper.log"

    # Add mocks to PATH
    chmod +x "$PROJECT_ROOT/tests/mocks/crontab"
    export PATH="$PROJECT_ROOT/tests/mocks:$PATH"

    # Verify crontab mock
    if [ "$(which crontab)" != "$PROJECT_ROOT/tests/mocks/crontab" ]; then
        echo "Error: Mock crontab not found in PATH"
        exit 1
    fi

    # Setup initial mock crontab with the job
    echo "00 10 * * * $HOME/scripts/bing_wallpaper.sh" > "$HOME/crontab.mock"

    export FORCE_STDIN=1
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "Uninstaller aborts when user denies confirmation" {
    # Pipe "N" to stdin
    run bash "$PROJECT_ROOT/uninstall.sh" <<< "N"

    [ "$status" -eq 0 ]

    # Verify files still exist
    [ -f "$HOME/scripts/bing_wallpaper.sh" ]
    [ -f "$HOME/scripts/wallpaper.log" ]

    # Verify cron still exists
    run cat "$HOME/crontab.mock"
    [[ "$output" == *"bing_wallpaper.sh"* ]]
}

@test "Uninstaller removes files and cron job on confirmation" {
    # Pipe "y" to stdin
    run bash "$PROJECT_ROOT/uninstall.sh" <<< "y"

    [ "$status" -eq 0 ]

    # Verify files removed
    [ ! -f "$HOME/scripts/bing_wallpaper.sh" ]
    [ ! -f "$HOME/scripts/wallpaper.log" ]

    # Verify directory removed (since it was empty)
    [ ! -d "$HOME/scripts" ]

    # Verify cron entry removed
    run cat "$HOME/crontab.mock"
    [[ "$output" != *"bing_wallpaper.sh"* ]]
}

@test "Uninstaller handles missing files gracefully" {
    # Remove files beforehand to trigger 'else' branches
    rm "$HOME/scripts/bing_wallpaper.sh"
    rm "$HOME/scripts/wallpaper.log"

    run bash "$PROJECT_ROOT/uninstall.sh" <<< "y"

    # Capture output to check logic flow
    UNINSTALL_OUTPUT="$output"

    [ "$status" -eq 0 ]

    # Should still try to remove cron
    run cat "$HOME/crontab.mock"
    [[ "$output" != *"bing_wallpaper.sh"* ]]

    # Verify output contains "not found" messages to confirm path execution
    [[ "$UNINSTALL_OUTPUT" == *"Script not found"* ]]
    [[ "$UNINSTALL_OUTPUT" == *"Log file not found"* ]]
}

@test "Uninstaller does not remove scripts directory if it contains other files" {
    # Add an extra file
    touch "$HOME/scripts/other_script.sh"

    run bash "$PROJECT_ROOT/uninstall.sh" <<< "y"

    [ "$status" -eq 0 ]

    # Standard files gone
    [ ! -f "$HOME/scripts/bing_wallpaper.sh" ]

    # Dir and other file remain
    [ -d "$HOME/scripts" ]
    [ -f "$HOME/scripts/other_script.sh" ]

    # Verify message
    [[ "$output" == *"is not empty, skipping removal"* ]]
}

@test "Uninstaller handles 'no crontab entry' gracefully" {
    # Ensure crontab is empty
    echo "" > "$HOME/crontab.mock"

    run bash "$PROJECT_ROOT/uninstall.sh" <<< "y"
    [ "$status" -eq 0 ]
    [[ "$output" == *"No crontab entry found"* ]]
}
