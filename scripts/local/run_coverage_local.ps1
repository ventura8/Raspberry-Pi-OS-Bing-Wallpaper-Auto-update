$ErrorActionPreference = "Stop"
$workspace = (Get-Location).Path
$coverageDir = Join-Path $workspace "coverage"

function Assert-LastExitCode {
    param([string]$Message)
    if ($LASTEXITCODE -ne 0) {
        Write-Host $Message -ForegroundColor Red
        exit 1
    }
}

if (!(Test-Path $coverageDir)) {
    New-Item -ItemType Directory -Path $coverageDir | Out-Null
}

Write-Host "Building Docker image..." -ForegroundColor Cyan
docker build --no-cache -t wallpaper-test .
Assert-LastExitCode "Docker build failed."

Write-Host "Running mandatory quality checks..." -ForegroundColor Cyan
docker run --rm -v "${workspace}:/workdir" -w /workdir wallpaper-test bash scripts/quality_checks.sh
Assert-LastExitCode "Quality checks failed."

Write-Host "Running tests with coverage..." -ForegroundColor Cyan
docker run --rm `
    -v "${workspace}:/app/workspace" `
    -w /app/workspace `
    wallpaper-test bash tests/run_coverage.sh
Assert-LastExitCode "Coverage test run failed."

Write-Host "Transforming coverage and generating badge..." -ForegroundColor Cyan
docker run --rm `
    -v "${workspace}:/workdir" `
    -w /workdir `
    wallpaper-test python3 tests/transform_coverage.py coverage/cobertura.xml
Assert-LastExitCode "Coverage transform failed."

Write-Host "Updating local coverage badge..." -ForegroundColor Cyan
if (Test-Path "badge.svg") {
    if (!(Test-Path "assets")) { New-Item -ItemType Directory -Path "assets" | Out-Null }
    Move-Item -Path "badge.svg" -Destination "assets/coverage.svg" -Force
    Write-Host "Badge updated: assets/coverage.svg" -ForegroundColor Green
}

Write-Host "Coverage report generated in $coverageDir" -ForegroundColor Green
