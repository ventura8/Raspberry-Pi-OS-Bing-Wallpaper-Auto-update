#!/bin/bash

# ==========================================
# Automated Uninstaller for Bing Wallpaper
# ==========================================

# Text Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting Bing Wallpaper Uninstallation...${NC}"

# Helper function for user input
ask_user() {
  local prompt="$1"
  local var_name="$2"
  if [[ -z "$FORCE_STDIN" ]] && [[ -c /dev/tty ]]; then
    read -r -p "$prompt" "${var_name?}" </dev/tty
  else
    read -r -p "$prompt" "${var_name?}"
  fi
  local read_status=$?
  # A last line without a trailing newline still counts as an answer
  if [[ "$read_status" -ne 0 ]] && [[ -z "${!var_name}" ]]; then
    return "$read_status"
  fi
  return 0
}

# Abort when a prompt hits end of input instead of silently using defaults
input_closed() {
  echo -e "${RED}Error: No input received (end of input). Aborting.${NC}" >&2
  exit 1
}

# Define paths
INSTALL_DIR="$HOME/scripts"
SCRIPT_FILE="$INSTALL_DIR/bing_wallpaper.sh"
LOG_FILE="$INSTALL_DIR/wallpaper.log"

# Interactive confirmation
ask_user "Are you sure you want to remove Bing Wallpaper and its scheduled tasks? (y/N): " CONFIRM || input_closed

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo -e "${YELLOW}Uninstallation cancelled.${NC}"
  exit 0
fi

# 1. Remove files
# ---------------
echo -e "${BLUE}Removing files...${NC}"

if [[ -f "$SCRIPT_FILE" ]]; then
  rm "$SCRIPT_FILE"
  echo -e "${GREEN}Removed script: $SCRIPT_FILE${NC}"
else
  echo -e "${YELLOW}Script not found: $SCRIPT_FILE${NC}"
fi

if [[ -f "$LOG_FILE" ]]; then
  rm "$LOG_FILE"
  echo -e "${GREEN}Removed log file: $LOG_FILE${NC}"
else
  echo -e "${YELLOW}Log file not found: $LOG_FILE${NC}"
fi

# Optional: Remove directory if empty?
# Only if it's exactly the install dir and empty.
if [[ -d "$INSTALL_DIR" ]]; then
  # count files
  if [[ -z "$(ls -A "$INSTALL_DIR")" ]]; then
    rmdir "$INSTALL_DIR"
    echo -e "${GREEN}Removed empty directory: $INSTALL_DIR${NC}"
  else
    echo -e "${YELLOW}Directory $INSTALL_DIR is not empty, skipping removal.${NC}"
  fi
fi

# 2. Remove Cron Job
# ------------------
echo -e "${BLUE}Removing scheduled tasks...${NC}"

# Check for existing installation in crontab
EXISTING_CRON=$(crontab -l 2>/dev/null)
if echo "$EXISTING_CRON" | grep -q "bing_wallpaper.sh"; then
  # Remove entry (grep -v) and update crontab
  (echo "$EXISTING_CRON" | grep -Fv -- "$INSTALL_DIR/bing_wallpaper.sh") | crontab -
  echo -e "${GREEN}Removed crontab entry.${NC}"
else
  echo -e "${YELLOW}No crontab entry found.${NC}"
fi

# 3. Finalize
# -----------
echo -e "${GREEN}==============================================${NC}"
echo -e "${GREEN}SUCCESS: Uninstallation Complete!${NC}"
echo -e "${GREEN}==============================================${NC}"
