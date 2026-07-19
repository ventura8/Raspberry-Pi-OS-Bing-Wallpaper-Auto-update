#!/bin/bash

# ==========================================
# Bing Wallpaper Script for Raspberry Pi OS
# ==========================================

# Log file path
LOG_FILE="$HOME/scripts/wallpaper.log"

trim_leading_non_alnum() {
  local value="$1"
  while [[ -n "$value" && ! "$value" =~ ^[[:alnum:]] ]]; do
    value="${value#?}"
  done
  printf '%s' "$value"
}

# Function for consistent logging with timestamps
log() {
  local msg
  msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"

  # Ensure log directory exists (just in case)
  mkdir -p "$(dirname "$LOG_FILE")"

  # Append to log file
  echo "$msg" >>"$LOG_FILE"

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

# Parse into title and copyright holder safely
TITLE="$FULL_COPYRIGHT"
COPYRIGHT=""
if [[ "$FULL_COPYRIGHT" == *"("*")" ]]; then
  TITLE="${FULL_COPYRIGHT% (*}"
  COPYRIGHT="${FULL_COPYRIGHT##*(}"
  COPYRIGHT="${COPYRIGHT%)}"
fi

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
  CLEAN_LOG_COPYRIGHT="$(trim_leading_non_alnum "$COPYRIGHT")"
  log "Copyright: $CLEAN_LOG_COPYRIGHT"
fi

# Modify URL for 4K if requested
if [ "$RESOLUTION" = "4k" ]; then
  REL_URL="${REL_URL/1920x1080/UHD}"
  log "Requesting 4K (UHD) resolution..."
fi

# Construct the full URL
FULL_URL="https://www.bing.com$REL_URL"
log "Found image URL: $REL_URL"

# 3. Download the Image
# ---------------------
DATE=$(date +%Y-%m-%d)

# Sanitize variables for filename
SAFE_TITLE="${TITLE//[^a-zA-Z0-9 ._-]/-}"
CLEAN_COPYRIGHT="$(trim_leading_non_alnum "$COPYRIGHT")"
SAFE_COPYRIGHT="${CLEAN_COPYRIGHT//[^a-zA-Z0-9 ._-]/-}"

if [ -z "$SAFE_TITLE" ]; then SAFE_TITLE="Bing_Wallpaper"; fi

FILENAME="${DATE} - ${SAFE_TITLE} - ${SAFE_COPYRIGHT}.jpg"
FILEPATH="$SAVE_DIR/$FILENAME"

# Always download the wallpaper (overwrite if it exists)
log "Downloading wallpaper to: $FILEPATH"
curl -s -o "$FILEPATH" "$FULL_URL"

# 4. Set the Wallpaper
# --------------------

set_xfce_wallpaper_existing() {
  local wp_path="$1"
  local properties

  properties=$(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep -E "last-image|image-path")
  [ -z "$properties" ] && return 1

  echo "$properties" | while read -r property; do
    xfconf-query -c xfce4-desktop -p "$property" -s "$wp_path"
  done

  log "Wallpaper updated via XFCE (xfconf-query)."
  return 0
}

set_xfce_wallpaper_fallback() {
  local wp_path="$1"
  local wallpaper_set=false
  local monitors=""

  log "No existing backdrop properties. Attempting to create them based on connected monitors..."

  if command -v xrandr >/dev/null 2>&1; then
    monitors=$(xrandr --query 2>/dev/null | grep -iE " connected|primary" | awk '{print $1}')
  fi

  if [ -z "$monitors" ]; then
    log "xrandr detection failed or no monitors found. Trying common default monitor names..."
    monitors="0 1 default"
  fi

  for monitor in $monitors; do
    monitor="${monitor//[^a-zA-Z0-9-]/}"
    [ -z "$monitor" ] && continue

    for prop_suffix in "last-image" "image-path"; do
      local prop_path
      prop_path="/backdrop/screen0/monitor${monitor}/workspace0/${prop_suffix}"
      log "Attempting to set/create property: $prop_path"
      if xfconf-query -c xfce4-desktop -p "$prop_path" -n -t string -s "$wp_path" 2>/dev/null; then
        wallpaper_set=true
        log "Wallpaper property set for monitor $monitor (${prop_suffix})."
      fi
    done
  done

  if [ "$wallpaper_set" = "false" ]; then
    log "XFCE detected, but could not set wallpaper even with fallbacks. Listing all properties for diagnostic:"
    xfconf-query -c xfce4-desktop -l >>"$LOG_FILE" 2>&1
    return 1
  fi

  return 0
}

set_wallpaper_xfce() {
  local wp_path="$1"

  [ "$XDG_CURRENT_DESKTOP" != "XFCE" ] && return 1
  command -v xfconf-query >/dev/null 2>&1 || return 1

  log "Detected XFCE. Updating backdrop properties..."

  if set_xfce_wallpaper_existing "$wp_path"; then
    return 0
  fi

  set_xfce_wallpaper_fallback "$wp_path"
}

set_wallpaper_wayfire() {
  local wp_path="$1"
  local wayfire_config="$HOME/.config/wayfire.ini"

  pgrep -x "wayfire" >/dev/null || return 1
  [ -f "$wayfire_config" ] || return 1
  grep -q "image =" "$wayfire_config" || return 1

  sed -i "s|image = .*|image = $wp_path|" "$wayfire_config"
  log "Wallpaper updated via Wayfire Config."
  return 0
}

set_wallpaper_pcmanfm() {
  local wp_path="$1"
  local out

  command -v pcmanfm >/dev/null 2>&1 || return 1

  if out=$(pcmanfm --set-wallpaper "$wp_path" --wallpaper-mode=fit 2>&1); then
    log "Wallpaper updated via PCManFM."
    return 0
  fi

  log "PCManFM standard mode failed: $out"
  log "Attempting pcmanfm with labwc profile..."
  if pcmanfm --profile labwc --set-wallpaper "$wp_path" --wallpaper-mode=fit >/dev/null 2>&1; then
    log "Wallpaper updated via PCManFM (Labwc Profile)."
    return 0
  fi

  return 1
}

set_wallpaper() {
  local wp_path="$1"

  set_wallpaper_xfce "$wp_path" && return 0
  set_wallpaper_wayfire "$wp_path" && return 0
  set_wallpaper_pcmanfm "$wp_path" && return 0

  return 1
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
