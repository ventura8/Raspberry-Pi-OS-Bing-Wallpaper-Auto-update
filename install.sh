#!/bin/bash

# ==========================================
# Automated Installer for Bing Wallpaper
# ==========================================

# Text Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting Fully Automated Bing Wallpaper Installation...${NC}"

# Helper function for user input
ask_user() {
    local prompt="$1"
    local var_name="$2"
    if [ -z "$FORCE_STDIN" ] && [ -c /dev/tty ]; then
        read -r -p "$prompt" "${var_name?}" < /dev/tty
    else
        read -r -p "$prompt" "${var_name?}"
    fi
}

# 1. Setup Directories
# --------------------
INSTALL_DIR="$HOME/scripts"
mkdir -p "$INSTALL_DIR"

# 2. Download the Main Script
# ---------------------------
# Pointing to the ventura8 repository
SCRIPT_URL="https://raw.githubusercontent.com/ventura8/Raspberry-Pi-OS-Bing-Wallpaper-Auto-update/main/bing_wallpaper.sh"

echo -e "Downloading latest script to ${INSTALL_DIR}/bing_wallpaper.sh..."
if ! curl -s -o "$INSTALL_DIR/bing_wallpaper.sh" "$SCRIPT_URL"; then
    echo -e "${RED}Error: Could not download script. Check your internet connection.${NC}"
    exit 1
fi

# 3. Permissions
# --------------
chmod +x "$INSTALL_DIR/bing_wallpaper.sh"
echo -e "${GREEN}Script installed and permissions set.${NC}"

# 3.1 Configure Region
# --------------------
echo -e "${BLUE}Configuring Bing Region...${NC}"
DEFAULT_REGION="en-WW"
ask_user "Enter Bing Region code (Default: en-WW, options: en-US, ja-JP, etc.): " USER_REGION

# Use default if input is empty
if [ -z "$USER_REGION" ]; then
    USER_REGION="$DEFAULT_REGION"
fi

# Update the script with the selected region
# We verify the strict pattern to enable safe replacement
if grep -q 'REGION="en-WW"' "$INSTALL_DIR/bing_wallpaper.sh"; then
    sed -i "s/REGION=\"en-WW\"/REGION=\"$USER_REGION\"/" "$INSTALL_DIR/bing_wallpaper.sh"
    echo -e "Region set to ${YELLOW}$USER_REGION${NC}."
else
    echo -e "${YELLOW}Warning: Could not update region automatically (pattern not found).${NC}"
fi

# 4. Automate with Crontab
# ------------------------
echo -e "${BLUE}Configuring automation (crontab)...${NC}"

# Default Time
CRON_HOUR="10"
CRON_MINUTE="00"

# Check for existing installation in crontab to show current status
EXISTING_CRON=$(crontab -l 2>/dev/null)
if echo "$EXISTING_CRON" | grep -q "$INSTALL_DIR/bing_wallpaper.sh"; then
    echo -e "${YELLOW}Existing configuration detected.${NC}"
fi

# Ask user for custom time
echo -e "Default update time is ${YELLOW}10:00 AM${NC}."
ask_user "Do you want to set a custom update time? (y/N): " CUSTOM_TIME

if [[ "$CUSTOM_TIME" =~ ^[Yy]$ ]]; then
    # Get Hour
    while true; do
        ask_user "Enter Hour (0-23): " INPUT_HOUR
        if [[ "$INPUT_HOUR" =~ ^[0-9]+$ ]] && [ "$INPUT_HOUR" -ge 0 ] && [ "$INPUT_HOUR" -le 23 ]; then
            CRON_HOUR=$INPUT_HOUR
            break
        else
            echo -e "${RED}Invalid hour. Please enter a number between 0 and 23.${NC}"
        fi
    done

    # Get Minute
    while true; do
        ask_user "Enter Minute (0-59): " INPUT_MINUTE
        if [[ "$INPUT_MINUTE" =~ ^[0-9]+$ ]] && [ "$INPUT_MINUTE" -ge 0 ] && [ "$INPUT_MINUTE" -le 59 ]; then
            CRON_MINUTE=$INPUT_MINUTE
            break
        else
            echo -e "${RED}Invalid minute. Please enter a number between 0 and 59.${NC}"
        fi
    done
fi

# Define the cron job line with LOG REDIRECTION
# Note: We do not add leading zeros to cron fields as some systems treat them as octal
CRON_JOB="$CRON_MINUTE $CRON_HOUR * * * $INSTALL_DIR/bing_wallpaper.sh >/dev/null 2>&1"

# Check if the job already exists
if echo "$EXISTING_CRON" | grep -q "$INSTALL_DIR/bing_wallpaper.sh"; then
    echo -e "${YELLOW}Updating existing schedule...${NC}"
    # Remove old entry (grep -v) and add new one
    (echo "$EXISTING_CRON" | grep -v "$INSTALL_DIR/bing_wallpaper.sh"; echo "$CRON_JOB") | crontab -
else
    echo -e "Adding new entry to crontab..."
    (echo "$EXISTING_CRON"; echo "$CRON_JOB") | crontab -
fi

# 5. Finalize
# -----------
echo -e "${GREEN}==============================================${NC}"
echo -e "${GREEN}SUCCESS: Installation & Automation Complete!${NC}"
echo -e "${GREEN}==============================================${NC}"
echo -e "The wallpaper will update every day at ${YELLOW}${CRON_HOUR}:${CRON_MINUTE}${NC}."
echo -e "Logs are silenced (no email) and saved to: ${BLUE}$INSTALL_DIR/wallpaper.log${NC}"
echo -e ""
echo -e "${BLUE}Applying the wallpaper now...${NC}"
"$INSTALL_DIR/bing_wallpaper.sh"
exit 0

