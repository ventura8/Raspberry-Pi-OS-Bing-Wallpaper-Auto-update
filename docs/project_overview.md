# Project Overview

The **Bing Wallpaper for Raspberry Pi** is a lightweight utility that automatically downloads and sets the daily Bing wallpaper as the desktop background on Raspberry Pi OS and Xubuntu. It supports XFCE, Wayfire, and Labwc compositors.

## Key Features

- **Multi-Environment Support**: Automatically detects and configures for XFCE (Xubuntu), Wayfire, and Labwc (Raspberry Pi OS).
- **Region Support**: Configurable Bing region/market for localized wallpapers.
- **4K Support**: Optional Ultra HD wallpaper downloads.
- **Smart Naming**: Files saved as `YYYY-MM-DD - Title - Copyright.jpg`.
- **Cron Integration**: Designed for scheduled daily updates.

## Directory Structure

```
├── bing_wallpaper.sh      # Main wallpaper script
├── install.sh             # Interactive installer
├── uninstall.sh           # Uninstaller script
├── Dockerfile             # Docker image for testing
├── tests/                 # BATS test suites
│   ├── bing_wallpaper_test.bats
│   ├── install_test.bats
│   ├── uninstall_test.bats
│   ├── e2e_tests.bats
│   ├── run_suite.sh       # Test runner
│   ├── run_coverage.sh    # Coverage runner
│   ├── transform_coverage.py  # XML processing & badge generation
│   ├── generate_summary.py    # Coverage summary generator
│   └── mocks/             # Mock binaries for testing
├── assets/                # Static assets
│   ├── screenshot_desktop.png
│   └── coverage.svg       # Coverage badge (locally generated)
├── .github/
│   └── workflows/
│       └── ci.yml         # GitHub Actions CI pipeline
├── run_tests_local.ps1    # Local test runner (Windows)
├── run_coverage_local.ps1 # Simple coverage runner (Windows)
└── README.md
```

## Target Platform

- **Raspberry Pi OS** (Bookworm and Trixie)
- **Xubuntu** (XFCE Desktop)
- Supports both 32-bit and 64-bit ARM architectures
