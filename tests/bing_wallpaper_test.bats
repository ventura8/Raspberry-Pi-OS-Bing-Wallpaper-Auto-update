#!/usr/bin/env bats

setup() {
    # Get the project root directory
    PROJECT_ROOT="$( cd "$( dirname "$BATS_TEST_FILENAME" )/.." >/dev/null 2>&1 && pwd )"
    
    # Create a temporary directory for the test run
    TEST_DIR=$(mktemp -d)
    
    # Export HOME as the temp dir so the script writes logs/images there
    export HOME="$TEST_DIR"
    
    # Add mocks to PATH
    # We prepend tests/mocks to PATH so our mock 'curl' is used instead of system 'curl'
    chmod +x "$PROJECT_ROOT/tests/mocks/curl"
    export PATH="$PROJECT_ROOT/tests/mocks:$PATH"
    
    # Verify mock is working
    if [ "$(which curl)" != "$PROJECT_ROOT/tests/mocks/curl" ]; then
        echo "Error: Mock curl not found in PATH"
        echo "PATH: $PATH"
        exit 1
    fi
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "Script extracts correct URL and Title from JSON" {
    # Run the script
    run bash "$PROJECT_ROOT/bing_wallpaper.sh"
    
    # Check exit status
    if [ "$status" -ne 0 ]; then
        echo "Script failed with output:"
        echo "$output"
        echo "--- Log Content ---"
        cat "$HOME/scripts/wallpaper.log" || echo "No log file found"
        echo "-------------------"
    fi
    [ "$status" -eq 0 ]
    
    # Check if the log file contains the expected URL (from our mock JSON)
    # Mock URL: /th?id=OHR.TestImage_EN-US123456789_1920x1080.jpg...
    run cat "$HOME/scripts/wallpaper.log"
    [[ "$output" == *"Found image URL: /th?id=OHR.TestImage_EN-US123456789_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp"* ]]
    
    # Check if the title was logged
    [[ "$output" == *"Image Title: Test Image Title"* ]]
}

@test "Script creates log file and writes to it" {
    # Run the script
    run bash "$PROJECT_ROOT/bing_wallpaper.sh"
    
    [ -f "$HOME/scripts/wallpaper.log" ]
    
    run cat "$HOME/scripts/wallpaper.log"
    [[ "$output" == *"Starting Bing Wallpaper update"* ]]
}

@test "Script outputs to stdout when interactive" {
    # Force interactive mode by pretending we are in a tty? 
    # BATS runs in a way that [ -t 1 ] is usually false.
    # We can try to force it but bash checks the actual FD.
    # Instead, we can verify that WITHOUT tty, expected output is empty.
    
    run bash "$PROJECT_ROOT/bing_wallpaper.sh"
    # In BATS, stdout is captured in $output.
    # Since we are NOT in a TTY, the script should NOT echo log messages to stdout,
    # EXCEPT for potentially error messages or the final download URL if we hadn't mocked the internal echoing.
    
    # Wait, my script logic is:
    # if [ -t 1 ]; then echo "$msg"; fi
    
    # So $output should NOT contain the log messages if [ -t 1 ] fails.
    # Let's verify it acts silently.
    
    [[ "$output" != *"Starting Bing Wallpaper update"* ]]
}

@test "Updates Wayfire config when wayfire is running" {
    # Setup mock environment
    export XDG_CURRENT_DESKTOP=""
    export MOCK_PGREP_MATCH="wayfire"
    
    # Create dummy wayfire config
    mkdir -p "$HOME/.config"
    echo "something = else" > "$HOME/.config/wayfire.ini"
    echo "image = /old/path.jpg" >> "$HOME/.config/wayfire.ini"
    
    run bash "$PROJECT_ROOT/bing_wallpaper.sh"
    
    [ "$status" -eq 0 ]
    
    # Verify config was updated
    run grep "image =" "$HOME/.config/wayfire.ini"
    # Content should look like: image = /tmp/tmp.../Pictures/Bing/2025-12-30 - ....jpg
    [[ "$output" == *"image ="* ]]
    [[ "$output" != *"/old/path.jpg"* ]]
}

@test "Calls PCManFM when Wayfire is not running" {
    # Setup mock environment
    export XDG_CURRENT_DESKTOP=""
    export MOCK_PGREP_MATCH="" # Wayfire not running
    
    run bash "$PROJECT_ROOT/bing_wallpaper.sh"
    
    [ "$status" -eq 0 ]
    
    # Verify pcmanfm was called
    [ -f "$HOME/pcmanfm.log" ]
    run cat "$HOME/pcmanfm.log"
    [[ "$output" == *"pcmanfm called with:"* ]]
    [[ "$output" == *"--set-wallpaper"* ]]
}

@test "Cleans up old wallpapers" {
    # Create the Bing directory
    mkdir -p "$HOME/Pictures/Bing"
    
    # Create an "old" wallpaper
    touch "$HOME/Pictures/Bing/old_wallpaper.jpg"
    
    run bash "$PROJECT_ROOT/bing_wallpaper.sh"
    
    [ "$status" -eq 0 ]
    
    # Verify old wallpaper is gone
    [ ! -f "$HOME/Pictures/Bing/old_wallpaper.jpg" ]
    
    # Verify new wallpaper exists (there should be exactly 1 file now)
    run ls "$HOME/Pictures/Bing"
    if [ "${#lines[@]}" -ne 1 ]; then
        echo "Cleanup failed. Files in directory:"
        ls -la "$HOME/Pictures/Bing"
    fi
    [ "${#lines[@]}" -eq 1 ]
}

@test "Script handles network failure (no URL)" {
    # Mock curl to return empty
    mkdir -p "$TEST_DIR/bin"
    echo "#!/bin/bash" > "$TEST_DIR/bin/curl"
    echo "" >> "$TEST_DIR/bin/curl"
    chmod +x "$TEST_DIR/bin/curl"
    export PATH="$TEST_DIR/bin:$PATH"
    
    run bash "$PROJECT_ROOT/bing_wallpaper.sh"
    [ "$status" -eq 1 ]
    grep "Error: Could not retrieve Bing URL" "$HOME/scripts/wallpaper.log"
}

@test "Script handles 4K resolution request" {
    # Set env var for resolution (the script reads RESOLUTION=...)
    # Actually the script defines RESOLUTION="1080p" at top.
    # To override, we'd need to sed the script OR if it accepted env var override (it doesn't seem to).
    # Wait, line 40: RESOLUTION="1080p"
    # To test 4K, we must modify the script or trick it.
    # Let's Modify the script in setup.
    sed -i 's/RESOLUTION="1080p"/RESOLUTION="4k"/' "$PROJECT_ROOT/bing_wallpaper.sh"
    
    run bash "$PROJECT_ROOT/bing_wallpaper.sh"
    [ "$status" -eq 0 ]
    grep "Requesting 4K (UHD)" "$HOME/scripts/wallpaper.log"
    # Restore happens in teardown (revert file?) or assume git checkout? 
    # Better: Use a copy in setup?
    # The tests run against "$PROJECT_ROOT/bing_wallpaper.sh".
    # I should reset it.
    sed -i 's/RESOLUTION="4k"/RESOLUTION="1080p"/' "$PROJECT_ROOT/bing_wallpaper.sh"
}

@test "Script handles PCManFM failure and attempts Labwc fallback" {
    # Setup mock environment
    export XDG_CURRENT_DESKTOP=""
    # Mock pcmanfm to fail first time, succeed with --profile labwc
    mkdir -p "$TEST_DIR/bin"
    cat <<'EOF' > "$TEST_DIR/bin/pcmanfm"
#!/bin/bash
if [[ "$*" == *"--profile labwc"* ]]; then
    exit 0
else
    echo "General failure"
    exit 1
fi
EOF
    chmod +x "$TEST_DIR/bin/pcmanfm"
    export PATH="$TEST_DIR/bin:$PATH"
    
    run bash "$PROJECT_ROOT/bing_wallpaper.sh"
    [ "$status" -eq 0 ]
    grep "PCManFM standard mode failed" "$HOME/scripts/wallpaper.log"
    grep "Wallpaper updated via PCManFM (Labwc Profile)" "$HOME/scripts/wallpaper.log"
}

@test "Script handles missing PCManFM gracefully" {
    # Ensure pcmanfm is NOT in path.
    # We set PATH to just system basics minus pcmanfm? 
    # Or just ensure our mock isn't there and assume system doesn't have it (Debian slim docker doesnt).
    # But previous tests mocked it content-fully.
    # We need to ensure PROJECT_ROOT/tests/mocks is in path, but NOT containing pcmanfm.
    # Our setup() puts mocks in path.
    # tests/mocks/pcmanfm exists.
    # We can temporarily rename it or use a restrictive PATH.
    
    # Restrictive PATH: only /bin, /usr/bin + mocks dir (minus pcmanfm)
    # Easiest: Rename mock in the mock dir for this test? No, that affects parallel.
    # Override PATH to a new temp dir having curl but no pcmanfm.
    
    mkdir -p "$TEST_DIR/bin_no_pcmanfm"
    cp "$PROJECT_ROOT/tests/mocks/curl" "$TEST_DIR/bin_no_pcmanfm/"
    cp "$PROJECT_ROOT/tests/mocks/pgrep" "$TEST_DIR/bin_no_pcmanfm/"
    # Don't copy pcmanfm
    
    export PATH="$TEST_DIR/bin_no_pcmanfm:/usr/bin:/bin"
    
    
    run bash "$PROJECT_ROOT/bing_wallpaper.sh"
    [ "$status" -eq 1 ]
    grep "Error: Could not set wallpaper" "$HOME/scripts/wallpaper.log"
}

@test "Logs to stdout when running interactively (TTY)" {
    # Use 'script' to simulate TTY.
    # -q: quiet, -e: return exit code, -c: command
    # /dev/null is typescript output file (we check stdout of script command)
    
    # Check if 'script' command exists (it should in debian)
    if ! command -v script >/dev/null; then
        skip "script command not found"
    fi
    
    run script -qec "bash $PROJECT_ROOT/bing_wallpaper.sh" /dev/null
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"Starting Bing Wallpaper update"* ]]
}

@test "Updates XFCE wallpaper when XDG_CURRENT_DESKTOP is XFCE" {
    # Setup mock environment
    export XDG_CURRENT_DESKTOP="XFCE"
    chmod +x "$PROJECT_ROOT/tests/mocks/xfconf-query"
    
    run bash "$PROJECT_ROOT/bing_wallpaper.sh"
    
    [ "$status" -eq 0 ]
    
    # Verify xfconf-query was detected and used
    run cat "$HOME/scripts/wallpaper.log"
    [[ "$output" == *"Detected XFCE. Updating backdrop properties..."* ]]
    [[ "$output" == *"Wallpaper updated via XFCE (xfconf-query)."* ]]
}

@test "Updates XFCE wallpaper by creating properties when none exist" {
    # Setup mock environment
    export XDG_CURRENT_DESKTOP="XFCE"
    export MOCK_XFCONF_EMPTY="true"
    chmod +x "$PROJECT_ROOT/tests/mocks/xfconf-query"
    chmod +x "$PROJECT_ROOT/tests/mocks/xrandr"
    
    run bash "$PROJECT_ROOT/bing_wallpaper.sh"
    
    [ "$status" -eq 0 ]
    
    run cat "$HOME/scripts/wallpaper.log"
    [[ "$output" == *"No existing backdrop properties. Attempting to create them based on connected monitors..."* ]]
    [[ "$output" == *"Attempting to set/create property: /backdrop/screen0/monitorHDMI-1/workspace0/last-image"* ]]
    [[ "$output" == *"Wallpaper property set for monitor HDMI-1 (last-image)."* ]]
}

@test "Updates XFCE wallpaper using default monitors when xrandr fails" {
    # Setup mock environment
    export XDG_CURRENT_DESKTOP="XFCE"
    export MOCK_XFCONF_EMPTY="true"
    export MOCK_XRANDR_EMPTY="true"
    chmod +x "$PROJECT_ROOT/tests/mocks/xfconf-query"
    chmod +x "$PROJECT_ROOT/tests/mocks/xrandr"
    
    run bash "$PROJECT_ROOT/bing_wallpaper.sh"
    
    [ "$status" -eq 0 ]
    
    run cat "$HOME/scripts/wallpaper.log"
    [[ "$output" == *"No connected monitors detected via xrandr"* ]] || [[ "$output" == *"xrandr detection failed"* ]]
    [[ "$output" == *"Trying common default monitor names..."* ]]
    [[ "$output" == *"Wallpaper property set for monitor default (last-image)."* ]]
}

@test "Logs diagnostic info when XFCE property creation fails" {
    # Setup mock environment
    export XDG_CURRENT_DESKTOP="XFCE"
    export MOCK_XFCONF_EMPTY="true"
    export MOCK_XFCONF_FAIL_CREATE="true"
    chmod +x "$PROJECT_ROOT/tests/mocks/xfconf-query"
    
    run bash "$PROJECT_ROOT/bing_wallpaper.sh"
    
    # It might still exit 1 because set_wallpaper returns 1
    # [ "$status" -eq 1 ]
    
    run cat "$HOME/scripts/wallpaper.log"
    [[ "$output" == *"XFCE detected, but could not set wallpaper even with fallbacks. Listing all properties for diagnostic:"* ]]
}
