#!/bin/bash
# shellcheck disable=SC2001

# ==========================================
# Bing Wallpaper Script for Raspberry Pi OS
# ==========================================

# Log file path
LOG_FILE="$HOME/scripts/wallpaper.log"

# Function for consistent logging with timestamps
log() {
    local msg
    msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    
    # Ensure log directory exists (just in case)
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # Append to log file
    echo "$msg" >> "$LOG_FILE"
    
    # If running interactively, also print to stdout so manual runs still show output
    if [ -t 1 ]; then
        echo "$msg"
    fi
}

# 1. Configuration
# ----------------
# We will save images to a 'Bing' folder in your Pictures directory
SAVE_DIR="$HOME/Pictures/Bing"
KEEP_OLD="false" # Set to "true" to keep history of all wallpapers

# Region/Market for Bing Wallpaper
# Defaults to "en-WW" (Global). 
REGION="en-WW"

# Resolution
# Options: "1080p" (Default) or "4k"
RESOLUTION="1080p"

log "Starting Bing Wallpaper update for region: $REGION ($RESOLUTION)"

mkdir -p "$SAVE_DIR"

# 2. Get the Image URL
# --------------------
# Fetch the JSON data from Bing's API (idx=0 is today, n=1 is one image)
API_URL="https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=$REGION"
JSON_DATA=$(curl -s "$API_URL")

# Extract the relative URL using strict grep and cut (more portable than grep -P)
# We look for "url":"..." and take the content inside quotes
# grep -o finds the pattern, cut extracts the value
REL_URL=$(echo "$JSON_DATA" | grep -o '"url":"[^"]*"' | head -n 1 | sed 's/"url":"//;s/"$//')

# Extract the full copyright string
FULL_COPYRIGHT=$(echo "$JSON_DATA" | grep -o '"copyright":"[^"]*"' | head -n 1 | sed 's/"copyright":"//;s/"$//')

# Parse into Title and Copyright Holder safely
TITLE=$(echo "$FULL_COPYRIGHT" | sed 's/ ([^()]*)$//')
COPYRIGHT=$(echo "$FULL_COPYRIGHT" | sed -n 's/.*(\(.*\))$/\1/p')

# If we couldn't find a URL, exit safely
if [ -z "$REL_URL" ]; then
    log "Error: Could not retrieve Bing URL. Check your internet connection."
    exit 1
fi

# Log image details
if [ -n "$TITLE" ]; then
    log "Image Title: $TITLE"
fi
if [ -n "$COPYRIGHT" ]; then
    CLEAN_LOG_COPYRIGHT=$(echo "$COPYRIGHT" | sed 's/^[^a-zA-Z0-9]*//')
    log "Copyright: $CLEAN_LOG_COPYRIGHT"
fi

# Modify URL for 4K if requested
if [ "$RESOLUTION" = "4k" ]; then
    REL_URL=$(echo "$REL_URL" | sed 's/1920x1080/UHD/')
    log "Requesting 4K (UHD) resolution..."
fi

# Construct the full URL
FULL_URL="https://www.bing.com$REL_URL"
log "Found image URL: $REL_URL"

# 3. Download the Image
# ---------------------
DATE=$(date +%Y-%m-%d)

# Sanitize variables for filename
SAFE_TITLE=$(echo "$TITLE" | sed 's/[^a-zA-Z0-9 ._-]/-/g')
CLEAN_COPYRIGHT=$(echo "$COPYRIGHT" | sed 's/^[^a-zA-Z0-9]*//')
SAFE_COPYRIGHT=$(echo "$CLEAN_COPYRIGHT" | sed 's/[^a-zA-Z0-9 ._-]/-/g')

if [ -z "$SAFE_TITLE" ]; then SAFE_TITLE="Bing_Wallpaper"; fi

FILENAME="${DATE} - ${SAFE_TITLE} - ${SAFE_COPYRIGHT}.jpg"
FILEPATH="$SAVE_DIR/$FILENAME"

# Always download the wallpaper (overwrite if it exists)
log "Downloading wallpaper to: $FILEPATH"
curl -s -o "$FILEPATH" "$FULL_URL"

# 4. Set the Wallpaper
# --------------------

set_wallpaper() {
    local wp_path="$1"
    local wallpaper_set=false

    # ---------------------------------------------------------
    # OPTION 1: XFCE (Xubuntu / Raspberry Pi OS with XFCE)
    # ---------------------------------------------------------
    # Only attempt XFCE methods when XDG_CURRENT_DESKTOP is explicitly set to XFCE
    if [ "$XDG_CURRENT_DESKTOP" = "XFCE" ]; then
        # Check if xfconf-query is actually available
        if command -v xfconf-query >/dev/null 2>&1; then
            log "Detected XFCE. Updating backdrop properties..."
            # Find all properties that look like image paths (last-image or image-path) and update them
            # This covers multi-monitor setups and different XFCE versions
            PROPERTIES=$(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep -E "last-image|image-path")
            if [ -n "$PROPERTIES" ]; then
                echo "$PROPERTIES" | while read -r property; do
                    xfconf-query -c xfce4-desktop -p "$property" -s "$wp_path"
                done
                wallpaper_set=true
                log "Wallpaper updated via XFCE (xfconf-query)."
            else
                # No existing properties found - try to create them based on connected monitors
                log "No existing backdrop properties. Attempting to create them based on connected monitors..."
                
                # Use xrandr to get connected monitors
                if command -v xrandr >/dev/null 2>&1; then
                    MONITORS=$(xrandr --query 2>/dev/null | grep -iE " connected|primary" | awk '{print $1}')
                fi

                if [ -z "$MONITORS" ]; then
                    log "xrandr detection failed or no monitors found. Trying common default monitor names..."
                    MONITORS="0 1 default"
                fi

                # Use a for loop to avoid subshell scoping issues
                for monitor in $MONITORS; do
                    # Sanitize monitor name (remove non-alphanumeric except -)
                    monitor=$(echo "$monitor" | sed 's/[^a-zA-Z0-9-]//g')
                    [ -z "$monitor" ] && continue

                    # Try both 'last-image' and 'image-path' properties (covers different XFCE versions)
                    for prop_suffix in "last-image" "image-path"; do
                        PROP_PATH="/backdrop/screen0/monitor${monitor}/workspace0/${prop_suffix}"
                        log "Attempting to set/create property: $PROP_PATH"
                        if xfconf-query -c xfce4-desktop -p "$PROP_PATH" -n -t string -s "$wp_path" 2>/dev/null; then
                            wallpaper_set=true
                            log "Wallpaper property set for monitor $monitor (${prop_suffix})."
                        fi
                    done
                done
                
                # If still not set, log diagnostic info
                if [ "$wallpaper_set" = "false" ]; then
                    log "XFCE detected, but could not set wallpaper even with fallbacks. Listing all properties for diagnostic:"
                    xfconf-query -c xfce4-desktop -l >> "$LOG_FILE" 2>&1
                fi
            fi
        fi
    fi

    # ---------------------------------------------------------
    # OPTION 2: Wayfire (Raspberry Pi OS - Bookworm Wayland Default)
    # ---------------------------------------------------------
    if [ "$wallpaper_set" = "false" ] && pgrep -x "wayfire" >/dev/null; then
        WAYFIRE_CONFIG="$HOME/.config/wayfire.ini"
        if [ -f "$WAYFIRE_CONFIG" ]; then
            if grep -q "image =" "$WAYFIRE_CONFIG"; then
                sed -i "s|image = .*|image = $wp_path|" "$WAYFIRE_CONFIG"
                log "Wallpaper updated via Wayfire Config."
                wallpaper_set=true
            fi
        fi
    fi

    # ---------------------------------------------------------
    # OPTION 3: PCManFM (Raspberry Pi OS - Labwc / Legacy X11)
    # ---------------------------------------------------------
    if [ "$wallpaper_set" = "false" ] && command -v pcmanfm >/dev/null 2>&1; then
        # Try generic set-wallpaper (works for X11 LXDE)
        if OUT=$(pcmanfm --set-wallpaper "$wp_path" --wallpaper-mode=fit 2>&1); then
            log "Wallpaper updated via PCManFM."
            wallpaper_set=true
        else
            # Fallback for Labwc which sometimes requires strict profile usage
            log "PCManFM standard mode failed: $OUT"
            log "Attempting pcmanfm with labwc profile..."
            if pcmanfm --profile labwc --set-wallpaper "$wp_path" --wallpaper-mode=fit >/dev/null 2>&1; then
                log "Wallpaper updated via PCManFM (Labwc Profile)."
                wallpaper_set=true
            fi
        fi
    fi

    if [ "$wallpaper_set" = "true" ]; then
        return 0
    else
        return 1
    fi
}

# --- CRITICAL FIX: Set Environment Variables for Cron ---
# These are required for pcmanfm/xfconf to talk to the desktop session
export USER
USER=$(whoami)
export DISPLAY=:0
# XDG_RUNTIME_DIR is the magic key for Wayland
export XDG_RUNTIME_DIR
XDG_RUNTIME_DIR="/run/user/$(id -u)"

# Help xfconf-query/D-Bus find the session bus if not set
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
fi

# Try to auto-detect Wayland display if needed
if [ -z "$WAYLAND_DISPLAY" ]; then
    # Look for wayland-0, wayland-1, etc. inside the runtime dir
    WD=$(find "$XDG_RUNTIME_DIR" -name "wayland-*" 2>/dev/null | head -n 1 | xargs basename 2>/dev/null)
    if [ -n "$WD" ]; then export WAYLAND_DISPLAY="$WD"; fi
fi

# Attempt to set the wallpaper
if set_wallpaper "$FILEPATH"; then
    WALLPAPER_SET=true
else
    WALLPAPER_SET=false
fi

# 5. Cleanup & Final Status
# -------------------------
if [ "$WALLPAPER_SET" = "true" ]; then
    if [ "$KEEP_OLD" = "false" ]; then
        log "Cleaning up old wallpapers..."
        find "$SAVE_DIR" -type f ! -name "$FILENAME" -delete
    fi
    exit 0
else
    log "Error: Could not set wallpaper. Please check logs for details."
    exit 1
fi
