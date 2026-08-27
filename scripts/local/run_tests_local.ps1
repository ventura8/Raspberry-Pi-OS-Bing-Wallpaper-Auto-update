$ErrorActionPreference = "Stop"
$workspace = (Get-Location).Path

function Assert-LastExitCode {
    param([string]$Message)
    if ($LASTEXITCODE -ne 0) {
        Write-Host $Message -ForegroundColor Red
        exit 1
    }
}

function Invoke-Suite {
    param(
        [string]$CoverageSubdir,
        [string[]]$SuiteArgs
    )

    docker run --rm `
        --security-opt seccomp=unconfined `
        --cap-add SYS_PTRACE `
        -e COVERAGE=1 `
        -e COVERAGE_OUTPUT=/app/coverage `
        -v "${workspace}/coverage_inputs/${CoverageSubdir}:/app/coverage" `
        wallpaper-test ./tests/run_suite.sh @SuiteArgs

    Assert-LastExitCode ("Test suite failed: " + ($SuiteArgs -join " "))
}

Write-Host "Cleaning previous artifacts..." -ForegroundColor Cyan
if (Test-Path "coverage") { Remove-Item -Recurse -Force "coverage" }
if (Test-Path "coverage_inputs") { Remove-Item -Recurse -Force "coverage_inputs" }
New-Item -ItemType Directory -Force -Path "coverage" | Out-Null
New-Item -ItemType Directory -Force -Path "coverage_inputs/installer" | Out-Null
New-Item -ItemType Directory -Force -Path "coverage_inputs/component" | Out-Null
New-Item -ItemType Directory -Force -Path "coverage_inputs/system" | Out-Null

Write-Host "STAGE: Build Docker Image..." -ForegroundColor Cyan
docker build -t wallpaper-test .
Assert-LastExitCode "Docker build failed."

Write-Host "STAGE: Mandatory Quality Checks..." -ForegroundColor Cyan
docker run --rm -v "${workspace}:/workdir" -w /workdir wallpaper-test bash scripts/quality_checks.sh
Assert-LastExitCode "Quality checks failed."

Write-Host "STAGE: Unit Tests..." -ForegroundColor Cyan
Invoke-Suite -CoverageSubdir "installer" -SuiteArgs @("--file", "tests/install_test.bats")
Invoke-Suite -CoverageSubdir "installer" -SuiteArgs @("--file", "tests/uninstall_test.bats")

Write-Host "STAGE: Component Tests..." -ForegroundColor Cyan
Invoke-Suite -CoverageSubdir "component" -SuiteArgs @("--file", "tests/bing_wallpaper_test.bats")

Write-Host "STAGE: System Tests..." -ForegroundColor Cyan
Invoke-Suite -CoverageSubdir "system" -SuiteArgs @("--e2e-only")

Write-Host "STAGE: Merge & Report..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path "coverage/merged" | Out-Null

$mergeCommands = @(
    "echo 'Debug: kcov version'",
    "kcov --version",
    "echo 'Debug: Inputs'",
    "ls -R coverage_inputs",
    "echo 'Debug: Merging'",
    "kcov --merge coverage/merged coverage_inputs/installer/* coverage_inputs/component/* coverage_inputs/system/*",
    "echo 'Debug: contents of merged'",
    "ls -R coverage/merged",
    'merged_xml="$(find coverage/merged -name cobertura.xml | head -n 1)"',
    'if [ ! -f "$merged_xml" ]; then echo "Merged cobertura.xml not found" >&2; exit 1; fi',
    'cp "$merged_xml" coverage/cobertura.xml',
    "python3 tests/transform_coverage.py coverage/cobertura.xml",
    "echo 'Generating Summary...'",
    "python3 tests/generate_summary.py coverage/cobertura.xml | tee coverage-summary.md"
)

docker run --rm `
    --security-opt seccomp=unconfined `
    --cap-add SYS_PTRACE `
    --user 0 `
    -v "${workspace}:/workdir" `
    -w /workdir `
    wallpaper-test /bin/bash -c ($mergeCommands -join " && ")
Assert-LastExitCode "Coverage merge/report failed."

Write-Host "STAGE: Enforce Coverage Threshold (>=90%)..." -ForegroundColor Cyan
$thresholdScript = @'
import xml.etree.ElementTree as ET
root = ET.parse("coverage/cobertura.xml").getroot()
line_rate = float(root.get("line-rate", "0")) * 100
print("Total coverage: {:.2f}%".format(line_rate))
if line_rate < 90.0:
    raise SystemExit("Coverage below 90% threshold: {:.2f}%".format(line_rate))
'@
$thresholdScript | docker run --rm -i `
    -v "${workspace}:/workdir" `
    -w /workdir `
    wallpaper-test `
    python3 -
Assert-LastExitCode "Coverage below 90% threshold."

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

if (Test-Path "coverage-summary.md") {
    Write-Host "Coverage and complexity summary:" -ForegroundColor Cyan
    Get-Content "coverage-summary.md"
}
else {
    Write-Host "WARNING: coverage-summary.md not found." -ForegroundColor Yellow
}
