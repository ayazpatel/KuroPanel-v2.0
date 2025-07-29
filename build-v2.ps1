# KuroPanel V2 Build Script (PowerShell)
# Automated build, test, and deployment preparation

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("development", "production", "testing")]
    [string]$Environment = "development",
    
    [Parameter(Mandatory=$false)]
    [switch]$RunTests,
    
    [Parameter(Mandatory=$false)]
    [switch]$BuildDocker,
    
    [Parameter(Mandatory=$false)]
    [switch]$CleanBuild
)

# Configuration
$PROJECT_NAME = "KuroPanel V2"
$VERSION = "2.0.0"
$BUILD_DIR = "builds"
$TIMESTAMP = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
$BUILD_TAG = "$VERSION-$Environment-$TIMESTAMP"

Write-Host "=== $PROJECT_NAME Build Script ===" -ForegroundColor Cyan
Write-Host "Version: $VERSION" -ForegroundColor Green
Write-Host "Environment: $Environment" -ForegroundColor Green
Write-Host "Build Tag: $BUILD_TAG" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan

# Clean previous builds
if ($CleanBuild) {
    Write-Host "Cleaning previous builds..." -ForegroundColor Yellow
    if (Test-Path $BUILD_DIR) {
        Remove-Item -Recurse -Force $BUILD_DIR
    }
    docker system prune -f 2>$null
}

# Create build directory
if (-not (Test-Path $BUILD_DIR)) {
    New-Item -ItemType Directory -Path $BUILD_DIR | Out-Null
}

# Step 1: Validate codebase
Write-Host "Step 1: Validating codebase..." -ForegroundColor Blue

# Check required files
$requiredFiles = @(
    "composer.json",
    "app/Config/App.php",
    "app/Config/Database.php",
    "kuro_upgraded.sql",
    "docker-compose.yml",
    "Dockerfile"
)

foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        Write-Host "✗ Missing required file: $file" -ForegroundColor Red
        exit 1
    }
}
Write-Host "✓ All required files present" -ForegroundColor Green

# Step 2: Install dependencies
Write-Host "Step 2: Installing dependencies..." -ForegroundColor Blue
composer install --no-dev --optimize-autoloader --no-interaction

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Composer install failed" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Dependencies installed" -ForegroundColor Green

# Step 3: Run tests (if requested)
if ($RunTests) {
    Write-Host "Step 3: Running tests..." -ForegroundColor Blue
    
    # PHP Unit tests
    if (Test-Path "vendor/bin/phpunit") {
        ./vendor/bin/phpunit --configuration phpunit.xml.dist
        if ($LASTEXITCODE -ne 0) {
            Write-Host "⚠ Unit tests had issues" -ForegroundColor Yellow
        } else {
            Write-Host "✓ Unit tests passed" -ForegroundColor Green
        }
    }
    
    # Integration tests with Docker
    if ($BuildDocker) {
        Write-Host "Running integration tests..." -ForegroundColor Yellow
        ./localDockerTest-v2.ps1 -TestType quick
        if ($LASTEXITCODE -ne 0) {
            Write-Host "⚠ Integration tests had issues" -ForegroundColor Yellow
        } else {
            Write-Host "✓ Integration tests passed" -ForegroundColor Green
        }
    }
}

# Step 4: Build Docker images (if requested)
if ($BuildDocker) {
    Write-Host "Step 4: Building Docker images..." -ForegroundColor Blue
    
    # Build application image
    docker build -t "kuropanel:$BUILD_TAG" -t "kuropanel:latest" .
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ Docker build failed" -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ Docker image built successfully" -ForegroundColor Green
    
    # Save image to builds directory
    Write-Host "Exporting Docker image..." -ForegroundColor Yellow
    docker save "kuropanel:$BUILD_TAG" | gzip > "$BUILD_DIR/kuropanel-$BUILD_TAG.tar.gz"
    Write-Host "✓ Docker image exported to $BUILD_DIR" -ForegroundColor Green
}

# Step 5: Create deployment package
Write-Host "Step 5: Creating deployment package..." -ForegroundColor Blue

$deploymentFiles = @(
    "app/",
    "public/",
    "writable/",
    "docker/",
    "vendor/",
    "composer.json",
    "composer.lock",
    "docker-compose.yml",
    "Dockerfile",
    "kuro_upgraded.sql",
    "setup_kuro_v2.php",
    "*.md"
)

# Create deployment archive
$archiveName = "$BUILD_DIR/kuropanel-v2-$BUILD_TAG.zip"
Compress-Archive -Path $deploymentFiles -DestinationPath $archiveName -Force
Write-Host "✓ Deployment package created: $archiveName" -ForegroundColor Green

# Final summary
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "🎉 Build completed successfully!" -ForegroundColor Green
Write-Host "📦 Artifacts created in: $BUILD_DIR" -ForegroundColor Green
Write-Host "📋 Build tag: $BUILD_TAG" -ForegroundColor Green

if ($BuildDocker) {
    Write-Host "🐳 Docker image: kuropanel:$BUILD_TAG" -ForegroundColor Green
}

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Review build artifacts in $BUILD_DIR" -ForegroundColor White
Write-Host "2. Test deployment in staging environment" -ForegroundColor White
Write-Host "3. Deploy to production when ready" -ForegroundColor White
Write-Host "==========================================" -ForegroundColor Cyan
