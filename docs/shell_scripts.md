# Shell Scripts & Logic

This document explains the core shell scripts in the project.

## bing_wallpaper.sh

The main wallpaper management script with the following features:

### Configuration Variables (Top of File)

| Variable | Default | Description |
|----------|---------|-------------|
| `REGION` | `en-WW` | Bing market/region code |
| `RESOLUTION` | `1080p` | Target resolution (`1080p` or `4k`) |
| `KEEP_OLD` | `false` | Keep history of old wallpapers |

### Wallpaper Setting Logic

The script uses a dedicated `set_wallpaper()` function to detect the environment and apply changes:

1. **XFCE (Xubuntu)**: 
   - Detects `XDG_CURRENT_DESKTOP=XFCE` or availability of `xfconf-query`.
   - Uses `xfconf-query` to update `last-image` properties for all monitors/workspaces.

2. **Wayfire (Raspberry Pi OS Bookworm):** 
   - Detects running `wayfire` process.
   - Updates `~/.config/wayfire.ini` directly.

3. **PCManFM (Raspberry Pi OS Labwc/Legacy):** 
   - Primary: Uses `pcmanfm --set-wallpaper` (Legacy/LXDE).
   - Fallback: Uses `pcmanfm --profile labwc --set-wallpaper` (Newer Labwc setups).

### Core Logic Flow

1. Fetch JSON metadata from Bing API
2. Parse image URL, title, and copyright
3. Download image to `~/Pictures/` (or configured location)
4. Set wallpaper using appropriate method for compositor
5. Log result with timestamp

### Error Handling

- Network failures are logged and script exits gracefully
- Invalid JSON responses are caught and reported
- Missing dependencies trigger appropriate error messages

## install.sh

Interactive installer that:

1. Prompts for Bing region selection
2. Prompts for update schedule (default: 10:00 AM)
3. Creates `~/scripts/` directory
4. Copies `bing_wallpaper.sh` to installation location
5. Sets up cron job for automated updates
6. Runs the script immediately for first wallpaper

### Detection of Existing Installation

The installer checks for existing installations and offers to update settings rather than reinstall.

## uninstall.sh

Clean removal script that:

1. Removes the installed script
2. Removes cron job entries
3. Optionally removes downloaded wallpapers
4. Cleans up empty directories
