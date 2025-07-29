# Quick Build Test Script - Fallback Version
# Test the fallback Dockerfile before running the full build

param(
    [switch]$NoCache,
    [switch]$Verbose
)

# Enable strict mode
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    
    switch ($Color) {
        "Red" { Write-Host $Message -ForegroundColor Red }
        "Green" { Write-Host $Message -ForegroundColor Green }
        "Yellow" { Write-Host $Message -ForegroundColor Yellow }
        "Blue" { Write-Host $Message -ForegroundColor Blue }
        "Purple" { Write-Host $Message -ForegroundColor Magenta }
        "Cyan" { Write-Host $Message -ForegroundColor Cyan }
        default { Write-Host $Message -ForegroundColor White }
    }
}

Write-Host ""
Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Blue"
Write-ColorOutput "🔧 KUROPANEL V2 - FALLBACK BUILD TEST" "White"
Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Blue"
Write-Host ""

# Check if Docker is running
Write-ColorOutput "🔍 Checking Docker status..." "Yellow"
try {
    $dockerVersion = docker --version
    Write-ColorOutput "✅ Docker is available: $dockerVersion" "Green"
} catch {
    Write-ColorOutput "❌ Docker is not available or not running" "Red"
    Write-ColorOutput "Please start Docker Desktop and try again." "Yellow"
    exit 1
}

# Prepare build arguments
$buildArgs = @()
if ($NoCache) {
    $buildArgs += "--no-cache"
}
if ($Verbose) {
    $buildArgs += "--progress=plain"
}

# Test build with fallback Dockerfile
Write-ColorOutput "🚀 Starting fallback build test..." "Yellow"
Write-ColorOutput "Using: Dockerfile.production.fallback" "Cyan"

try {
    Write-ColorOutput "📦 Building with fallback configuration..." "Yellow"
    
    # Build using the fallback docker-compose
    & docker-compose -f docker-compose.production.fallback.yml build @buildArgs app
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "✅ FALLBACK BUILD SUCCESSFUL!" "Green"
        Write-ColorOutput "The fallback Dockerfile works. You can now run the full build." "Green"
        Write-Host ""
        Write-ColorOutput "To run the full application:" "Cyan"
        Write-ColorOutput "docker-compose -f docker-compose.production.fallback.yml up -d" "White"
    } else {
        Write-ColorOutput "❌ Fallback build failed with exit code: $LASTEXITCODE" "Red"
    }
} catch {
    Write-ColorOutput "❌ Build failed: $($_.Exception.Message)" "Red"
    exit 1
}

Write-Host ""
Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Blue"
