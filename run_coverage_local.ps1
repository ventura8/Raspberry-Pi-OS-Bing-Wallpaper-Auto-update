$currentDir = Get-Location
$coverageDir = Join-Path $currentDir "coverage"

# Create coverage directory if it doesn't exist
if (!(Test-Path $coverageDir)) {
    New-Item -ItemType Directory -Path $coverageDir | Out-Null
}

# Build the Docker image
Write-Host "Building Docker image..."
docker build --no-cache -t wallpaper-test .

# Run the coverage script in the container
Write-Host "Running tests with coverage..."
docker run --rm -v "${coverageDir}:/app/coverage" -v "${currentDir}/tests/run_coverage.sh:/app/tests/run_coverage.sh" -v "${currentDir}:/app/workspace" -w /app/workspace wallpaper-test bash tests/run_coverage.sh

# The script above might not run transform_coverage.py by default if it only runs run_coverage.sh. 
# Let's check run_coverage.sh
Write-Host "Transforming coverage and generating badge..."
docker run --rm -v "${currentDir}:/workdir" -w /workdir wallpaper-test python3 tests/transform_coverage.py coverage/cobertura.xml

# Move the locally generated badge to the assets directory
Write-Host "Updating local coverage badge..." -ForegroundColor Cyan
if (Test-Path "badge.svg") {
    if (!(Test-Path "assets")) { New-Item -ItemType Directory -Path "assets" | Out-Null }
    Move-Item -Path "badge.svg" -Destination "assets/coverage.svg" -Force
    Write-Host "Badge updated: assets/coverage.svg" -ForegroundColor Green
}

Write-Host "Coverage report generated in $coverageDir"
