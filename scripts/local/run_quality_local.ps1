$ErrorActionPreference = "Stop"
$workspace = (Get-Location).Path

function Assert-LastExitCode {
    param([string]$Message)
    if ($LASTEXITCODE -ne 0) {
        Write-Host $Message -ForegroundColor Red
        exit 1
    }
}

Write-Host "STAGE: Build Docker Image for Quality Checks..." -ForegroundColor Cyan
docker build -t wallpaper-test .
Assert-LastExitCode "Docker build failed."

Write-Host "STAGE: Run Quality Checks..." -ForegroundColor Cyan
docker run --rm `
    -v "${workspace}:/workdir" `
    -w /workdir `
    wallpaper-test bash scripts/quality_checks.sh

Assert-LastExitCode "Quality checks failed."

Write-Host "Quality checks passed." -ForegroundColor Green
