# Simple Build Script for KuroPanel V2
# Clean version without complex formatting

param(
    [switch]$NoCache,
    [switch]$Monitoring,
    [string]$Profile = "default"
)

# Enable strict mode
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Simple color output function
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    
    switch ($Color) {
        "Red" { Write-Host $Message -ForegroundColor Red }
        "Green" { Write-Host $Message -ForegroundColor Green }
        "Yellow" { Write-Host $Message -ForegroundColor Yellow }
        "Blue" { Write-Host $Message -ForegroundColor Blue }
        "Cyan" { Write-Host $Message -ForegroundColor Cyan }
        default { Write-Host $Message -ForegroundColor White }
    }
}

# Show header
function Show-Header {
    Write-Host ""
    Write-ColorOutput "============================================================" "Blue"
    Write-ColorOutput "🚀 KUROPANEL V2 - PRODUCTION BUILD" "White"
    Write-ColorOutput "============================================================" "Blue"
    Write-Host ""
}

# Check prerequisites
function Test-Prerequisites {
    Write-ColorOutput "🔍 Checking prerequisites..." "Yellow"
    
    # Check Docker
    try {
        $dockerVersion = docker --version
        Write-ColorOutput "✅ Docker: $dockerVersion" "Green"
    } catch {
        Write-ColorOutput "❌ Docker not found. Please install Docker Desktop." "Red"
        exit 1
    }
    
    # Check docker-compose
    try {
        $composeVersion = docker-compose --version
        Write-ColorOutput "✅ Docker Compose: $composeVersion" "Green"
    } catch {
        Write-ColorOutput "❌ Docker Compose not found." "Red"
        exit 1
    }
    
    Write-Host ""
}

# Docker build process
function Start-DockerBuild {
    Write-ColorOutput "📦 Starting Docker build process..." "Yellow"
    
    # Set Docker build environment
    $env:DOCKER_BUILDKIT = "1"
    $env:COMPOSE_DOCKER_CLI_BUILD = "1"
    
    # Prepare build arguments
    $buildArgs = @()
    if ($NoCache) {
        $buildArgs += "--no-cache"
    }
    $buildArgs += "--progress=plain"
    
    try {
        Write-ColorOutput "🔧 Building application container..." "Yellow"
        & docker-compose -f docker-compose.production.optimized.yml build @buildArgs
        
        if ($LASTEXITCODE -ne 0) {
            throw "Docker build failed with exit code $LASTEXITCODE"
        }
        
        Write-ColorOutput "✅ Docker build completed successfully" "Green"
    } catch {
        Write-ColorOutput "❌ Docker build failed: $($_.Exception.Message)" "Red"
        Write-ColorOutput "💡 Try using the fallback build: .\test-fallback-build.ps1" "Yellow"
        exit 1
    }
}

# Start services
function Start-Services {
    Write-ColorOutput "🚀 Starting services..." "Yellow"
    
    try {
        # Start database and cache first
        Write-ColorOutput "📊 Starting MySQL and Redis..." "Yellow"
        & docker-compose -f docker-compose.production.optimized.yml up -d mysql redis
        
        # Wait a bit for database to initialize
        Write-ColorOutput "⏳ Waiting for database initialization..." "Yellow"
        Start-Sleep -Seconds 10
        
        # Start main application
        Write-ColorOutput "🌐 Starting main application..." "Yellow"
        & docker-compose -f docker-compose.production.optimized.yml up -d app
        
        Write-ColorOutput "✅ Services started successfully" "Green"
    } catch {
        Write-ColorOutput "❌ Failed to start services: $($_.Exception.Message)" "Red"
        exit 1
    }
}

# Health check
function Test-ServiceHealth {
    Write-ColorOutput "🔍 Checking service health..." "Yellow"
    
    # Wait for services to be ready
    Write-ColorOutput "⏳ Waiting for services to be ready..." "Yellow"
    Start-Sleep -Seconds 30
    
    # Check service status
    Write-ColorOutput "📋 Service Status:" "Cyan"
    & docker-compose -f docker-compose.production.optimized.yml ps
}

# Show completion info
function Show-CompletionInfo {
    Write-Host ""
    Write-ColorOutput "============================================================" "Green"
    Write-ColorOutput "🎉 BUILD COMPLETED SUCCESSFULLY!" "Green"
    Write-ColorOutput "============================================================" "Green"
    Write-Host ""
    Write-ColorOutput "📌 Next Steps:" "Cyan"
    Write-ColorOutput "1. Access your application at: http://localhost" "Yellow"
    Write-ColorOutput "2. Check logs: docker-compose -f docker-compose.production.optimized.yml logs -f" "Yellow"
    Write-ColorOutput "3. Stop services: docker-compose -f docker-compose.production.optimized.yml down" "Yellow"
    Write-Host ""
}

# Main execution
try {
    Show-Header
    Test-Prerequisites
    Start-DockerBuild
    Start-Services
    
    if (-not $Monitoring) {
        Test-ServiceHealth
    }
    
    Show-CompletionInfo
} catch {
    Write-ColorOutput "❌ Build process failed: $($_.Exception.Message)" "Red"
    Write-ColorOutput "💡 Check the logs above for details" "Yellow"
    exit 1
}
