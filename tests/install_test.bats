#!/usr/bin/env bats

setup() {
    # Get the project root directory
    PROJECT_ROOT="$( cd "$( dirname "$BATS_TEST_FILENAME" )/.." >/dev/null 2>&1 && pwd )"
    
    # Create a temporary directory for the test run
    TEST_DIR=$(mktemp -d)
    
    # Export HOME as the temp dir so the script writes logs/images there
    export HOME="$TEST_DIR"
    
    # Add mocks to PATH
    chmod +x "$PROJECT_ROOT/tests/mocks/curl"
    chmod +x "$PROJECT_ROOT/tests/mocks/crontab"
    export PATH="$PROJECT_ROOT/tests/mocks:$PATH"
    
    # Verify mocks are working
    if [ "$(which curl)" != "$PROJECT_ROOT/tests/mocks/curl" ]; then
        echo "Error: Mock curl not found in PATH"
        exit 1
    fi
    if [ "$(which crontab)" != "$PROJECT_ROOT/tests/mocks/crontab" ]; then
        echo "Error: Mock crontab not found in PATH"
        exit 1
    fi
    
    export FORCE_STDIN=1
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "Installer creates directories and downloads script" {
    # Run installer with default inputs:
    # 1. Region: Enter (default en-WW)
    # 2. Custom Time: N
    run bash "$PROJECT_ROOT/install.sh" <<< "
N"
    
    [ "$status" -eq 0 ]
    
    # Verify directory creation
    [ -d "$HOME/scripts" ]
    
    # Verify script download
    [ -f "$HOME/scripts/bing_wallpaper.sh" ]
    
    # Verify permissions (executable)
    [ -x "$HOME/scripts/bing_wallpaper.sh" ]
}

@test "Installer sets default cron job (10:00 AM)" {
    # Run installer with default inputs (Region: Default, Time: Default)
    run bash "$PROJECT_ROOT/install.sh" <<< "
N"
    
    [ "$status" -eq 0 ]
    
    # Check crontab mock file
    [ -f "$HOME/crontab.mock" ]
    run cat "$HOME/crontab.mock"
    
    [[ "$output" == *"00 10 * * * $TEST_DIR/scripts/bing_wallpaper.sh >/dev/null 2>&1"* ]]
}

@test "Installer sets custom cron job (e.g. 08:30)" {
    # Input:
    # 1. Region: Enter (Default)
    # 2. Custom Time: y
    # 3. Hour: 08
    # 4. Minute: 30
    run bash "$PROJECT_ROOT/install.sh" <<< "
y
08
30"
    
    [ "$status" -eq 0 ]
    
    run cat "$HOME/crontab.mock"
    [[ "$output" == *"30 08 * * * $TEST_DIR/scripts/bing_wallpaper.sh >/dev/null 2>&1"* ]]
}

@test "Installer updates existing cron job instead of duplicating" {
    # 1. Install with default (10:00)
    run bash "$PROJECT_ROOT/install.sh" <<< "
N"
    [ "$status" -eq 0 ]
    
    # Verify 10:00 exists
    run cat "$HOME/crontab.mock"
    [[ "$output" == *"00 10 * * * $TEST_DIR/scripts/bing_wallpaper.sh >/dev/null 2>&1"* ]]
    
    # 2. Run again with custom (09:15)
    run bash "$PROJECT_ROOT/install.sh" <<< "
y
09
15"
    [ "$status" -eq 0 ]
    
    # Verify 09:15 exists AND 10:00 is GONE
    run cat "$HOME/crontab.mock"
    [[ "$output" == *"15 09 * * * $TEST_DIR/scripts/bing_wallpaper.sh >/dev/null 2>&1"* ]]
    [[ "$output" != *"00 10 * * * $TEST_DIR/scripts/bing_wallpaper.sh"* ]]
    
    # Verify there is only one line for the script
    run grep -c "bing_wallpaper.sh" "$HOME/crontab.mock"
    [ "$output" -eq 1 ]
}

@test "Installer sets custom region (ja-JP)" {
    # Input:
    # 1. Region: ja-JP
    # 2. Custom Time: N
    run bash "$PROJECT_ROOT/install.sh" <<< "ja-JP
N"
    
    [ "$status" -eq 0 ]
    
    # Verify the script content has been updated
    run grep 'REGION="ja-JP"' "$HOME/scripts/bing_wallpaper.sh"
    [ "$status" -eq 0 ]
    
    # Verify old default is gone
    run grep 'REGION="en-WW"' "$HOME/scripts/bing_wallpaper.sh"
    [ "$status" -eq 1 ]
}

@test "Installer handles network failure gracefully" {
    mkdir -p "$TEST_DIR/bin"
    echo "#!/bin/bash" > "$TEST_DIR/bin/curl"
    echo "exit 1" >> "$TEST_DIR/bin/curl"
    chmod +x "$TEST_DIR/bin/curl"
    export PATH="$TEST_DIR/bin:$PATH"
    
    run bash "$PROJECT_ROOT/install.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: Could not download script"* ]]
}

@test "Installer handles Region Pattern missing gracefully" {
    mkdir -p "$TEST_DIR/bin"
    echo "#!/bin/bash" > "$TEST_DIR/bin/curl"
    # Create a dummy bing_wallpaper.sh WITHOUT the pattern
    echo "echo 'Region not found here'" > "$TEST_DIR/dummy_script.sh"
    echo "cp \"$TEST_DIR/dummy_script.sh\" \"\$3\"" >> "$TEST_DIR/bin/curl"
    chmod +x "$TEST_DIR/bin/curl"
    export PATH="$TEST_DIR/bin:$PATH"

    run bash "$PROJECT_ROOT/install.sh" <<< "
N"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Warning: Could not update region automatically"* ]]
}

@test "Installer handles invalid hour/minute inputs before accepting valid ones" {
    # We use a simple input stream.
    # Input 1: Enter (Default Region)
    # Input 2: Y (Custom Time)
    # Input 3: 25 (Invalid Hour)
    # Input 4: 10 (Valid Hour)
    # Input 5: 99 (Invalid Minute)
    # Input 6: 30 (Valid Minute)
    
    run bash "$PROJECT_ROOT/install.sh" <<< "
Y
25
10
99
30"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Invalid hour"* ]]
    [[ "$output" == *"Invalid minute"* ]]
}

@test "Installer handles invalid hour non-numeric input" {
    run bash "$PROJECT_ROOT/install.sh" <<< "
Y
abc
10
30"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Invalid hour"* ]]
    [[ "$output" == *"10:30"* ]]
}

@test "Installer handles invalid minute non-numeric input" {
    run bash "$PROJECT_ROOT/install.sh" <<< "
Y
10
xyz
30"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Invalid minute"* ]]
    [[ "$output" == *"10:30"* ]]
}
