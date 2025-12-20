# run_tests_local.ps1
# Simulates the CI pipeline locally

$ErrorActionPreference = "Stop"
$Workspace = Get-Location

# Clean previous coverage
Write-Host "Cleaning previous artifacts..." -ForegroundColor Cyan
if (Test-Path "coverage") { Remove-Item -Recurse -Force "coverage" }
if (Test-Path "coverage_inputs") { Remove-Item -Recurse -Force "coverage_inputs" }
New-Item -ItemType Directory -Force -Path "coverage" | Out-Null
New-Item -ItemType Directory -Force -Path "coverage_inputs/installer" | Out-Null
New-Item -ItemType Directory -Force -Path "coverage_inputs/component" | Out-Null
New-Item -ItemType Directory -Force -Path "coverage_inputs/system" | Out-Null

# 1. Build Image
Write-Host "STAGE: Build Docker Image..." -ForegroundColor Cyan
docker build -t wallpaper-test .

if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker build failed." -ForegroundColor Red
    exit 1
}
    
# 2. Lint Checks
Write-Host "STAGE: Lint Checks..." -ForegroundColor Cyan
docker run --rm wallpaper-test /bin/sh -c "shellcheck install.sh uninstall.sh tests/*.sh"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Lint checks failed." -ForegroundColor Red
    exit 1
}

# 3. Unit Tests (Installer + Uninstall)
Write-Host "STAGE: Unit Tests..." -ForegroundColor Cyan

Write-Host "  -> Running Installer Tests..."
docker run --rm `
    --security-opt seccomp=unconfined `
    --cap-add SYS_PTRACE `
    -e COVERAGE=1 `
    -e COVERAGE_OUTPUT=/app/coverage `
    -v "${Workspace}/coverage_inputs/installer:/app/coverage" `
    wallpaper-test ./tests/run_suite.sh --installer-only

# 4. Component Tests
Write-Host "STAGE: Component Tests..." -ForegroundColor Cyan
docker run --rm `
    --security-opt seccomp=unconfined `
    --cap-add SYS_PTRACE `
    -e COVERAGE=1 `
    -e COVERAGE_OUTPUT=/app/coverage `
    -v "${Workspace}/coverage_inputs/component:/app/coverage" `
    wallpaper-test ./tests/run_suite.sh --file tests/bing_wallpaper_test.bats

# 5. System Tests
Write-Host "STAGE: System Tests..." -ForegroundColor Cyan
docker run --rm `
    --security-opt seccomp=unconfined `
    --cap-add SYS_PTRACE `
    -e COVERAGE=1 `
    -e COVERAGE_OUTPUT=/app/coverage `
    -v "${Workspace}/coverage_inputs/system:/app/coverage" `
    wallpaper-test ./tests/run_suite.sh --e2e-only

# 6. Merge & Report
Write-Host "STAGE: Merge & Report..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path "coverage/merged" | Out-Null

# We mount the whole workspace to access inputs and scripts
docker run --rm `
    --security-opt seccomp=unconfined `
    --cap-add SYS_PTRACE `
    --user 0 `
    -v "${Workspace}:/workdir" `
    -w /workdir `
    wallpaper-test /bin/bash -c "echo 'Debug: kcov version' && kcov --version && echo 'Debug: Inputs' && ls -R coverage_inputs && echo 'Debug: Merging' && kcov --merge coverage/merged coverage_inputs/installer/* coverage_inputs/component/* coverage_inputs/system/* && echo 'Debug: contents of merged' && ls -R coverage/merged && find coverage/merged -name cobertura.xml -exec cp {} coverage/cobertura.xml \; && python3 tests/transform_coverage.py coverage/cobertura.xml && echo 'Generating Summary...' && python3 tests/generate_summary.py coverage/cobertura.xml"

# Move the locally generated badge to the assets directory
Write-Host "Updating local coverage badge..." -ForegroundColor Cyan
if (Test-Path "badge.svg") {
    if (!(Test-Path "assets")) { New-Item -ItemType Directory -Path "assets" | Out-Null }
    Move-Item -Path "badge.svg" -Destination "assets/coverage.svg" -Force
    Write-Host "Badge updated: assets/coverage.svg" -ForegroundColor Green
}
else {
    Write-Host "WARNING: badge.svg not found after test run." -ForegroundColor Yellow
}

Write-Host "Pipeline Completed." -ForegroundColor Green
Write-Host "Validation: Checking for Cobertura XML..."
if (Test-Path "coverage/cobertura.xml") {
    Write-Host "SUCCESS: coverage/cobertura.xml generated." -ForegroundColor Green
    Get-Content "coverage/cobertura.xml" -TotalCount 20
}
else {
    Write-Host "FAILURE: coverage/cobertura.xml NOT found." -ForegroundColor Red
    exit 1
}
