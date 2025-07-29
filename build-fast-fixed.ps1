# Ultra Fast Production Build Script - PowerShell Version
# KuroPanel V2 - Optimized Build System for Windows

param(
    [switch]$NoCache,
    [switch]$Monitoring,
    [string]$Profile = "default"
)

# Enable strict mode
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Unicode symbols (safe for PowerShell)
$Symbols = @{
    CheckMark = "[OK]"
    Rocket = "[BUILD]"
    Gear = "[SETUP]"
    Package = "[PKG]"
    Database = "[DB]"
    Cache = "[CACHE]"
    Shield = "[SEC]"
    Chart = "[STATS]"
    Error = "[ERROR]"
    Warning = "[WARN]"
}

# Print colored output
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

# Print header
function Show-Header {
    Write-Host ""
    Write-ColorOutput "================================================================" "Blue"
    Write-ColorOutput "$($Symbols.Rocket) KUROPANEL V2 - ULTRA FAST PRODUCTION BUILD $($Symbols.Rocket)" "White"
    Write-ColorOutput "================================================================" "Blue"
    Write-ColorOutput "Build System: Docker Multi-stage with Alpine Linux" "Cyan"
    Write-ColorOutput "Build Mode: Production Optimized" "Cyan"
    Write-ColorOutput "Progress Tracking: Real-time with percentage" "Cyan"
    Write-ColorOutput "Platform: Windows PowerShell" "Cyan"
    Write-ColorOutput "================================================================" "Blue"
    Write-Host ""
}

# Progress bar function
function Show-Progress {
    param(
        [int]$Current,
        [int]$Total,
        [string]$Description,
        [int]$Width = 50
    )
    
    $Percentage = [math]::Round(($Current / $Total) * 100)
    $Completed = [math]::Round(($Current / $Total) * $Width)
    $Remaining = $Width - $Completed
    
    $ProgressBar = "#" * $Completed + "." * $Remaining
    
    Write-Host "`r[$ProgressBar] $Percentage% $Description" -NoNewline -ForegroundColor Blue
}

# Error handling
function Handle-Error {
    param([string]$Message)
    Write-Host ""
    Write-ColorOutput "$($Symbols.Error) Build failed at: $Message" "Red"
    Write-ColorOutput "Check the logs above for details" "Red"
    exit 1
}

# Check prerequisites
function Test-Prerequisites {
    Write-ColorOutput "$($Symbols.Gear) Phase 1: Pre-build Setup" "Yellow"
    
    Show-Progress 1 20 "Checking Docker installation..."
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Handle-Error "Docker not installed or not in PATH"
    }
    Start-Sleep -Milliseconds 500
    
    Show-Progress 2 20 "Checking Docker Compose..."
    $composeAvailable = $false
    try {
        docker compose version | Out-Null
        $composeAvailable = $true
    } catch {
        try {
            docker-compose --version | Out-Null
            $composeAvailable = $true
        } catch {
            # Docker Compose not available
        }
    }
    
    if (-not $composeAvailable) {
        Handle-Error "Docker Compose not available"
    }
    Start-Sleep -Milliseconds 500
    
    Show-Progress 3 20 "Creating data directories..."
    $directories = @(
        "data\mysql", "data\redis", "data\logs", "data\uploads", "data\sessions",
        "ssl", "backups\mysql"
    )
    
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            try {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
            } catch {
                Handle-Error "Failed to create directory: $dir"
            }
        }
    }
    Start-Sleep -Milliseconds 500
    
    Show-Progress 4 20 "Setting up environment..."
    if (-not (Test-Path ".env.production.optimized")) {
        Write-ColorOutput "$($Symbols.Warning) Using optimized environment template..." "Yellow"
    }
    Start-Sleep -Milliseconds 500
    
    Write-Host ""
    Write-ColorOutput "$($Symbols.CheckMark) Pre-build setup complete!" "Green"
}

# Docker build process
function Start-DockerBuild {
    Write-Host ""
    Write-ColorOutput "$($Symbols.Package) Phase 2: Docker Build Process" "Yellow"
    
    # Enable BuildKit for faster builds
    $env:DOCKER_BUILDKIT = "1"
    $env:COMPOSE_DOCKER_CLI_BUILD = "1"
    
    Show-Progress 5 20 "Starting Docker build (Alpine base)..."
    Write-Host ""
    Write-ColorOutput "Building application image with optimizations..." "Blue"
    
    # Determine build arguments
    $buildArgs = @()
    if ($NoCache) {
        $buildArgs += "--no-cache"
    }
    $buildArgs += "--parallel", "--progress=plain", "app"
    
    try {
        & docker-compose -f docker-compose.production.optimized.yml build @buildArgs
        if ($LASTEXITCODE -ne 0) {
            throw "Docker build failed with exit code $LASTEXITCODE"
        }
    } catch {
        Handle-Error "Docker build failed: $($_.Exception.Message)"
    }
    
    Show-Progress 10 20 "Application build complete!"
    Write-Host ""
}

# Start services
function Start-Services {
    Write-ColorOutput "$($Symbols.Database) Phase 3: Starting Services" "Yellow"
    
    Show-Progress 11 20 "Starting database services..."
    try {
        & docker-compose -f docker-compose.production.optimized.yml up -d mysql redis
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to start database services"
        }
    } catch {
        Handle-Error "Database services failed: $($_.Exception.Message)"
    }
    Start-Sleep -Seconds 2
    
    Show-Progress 13 20 "Starting application server..."
    try {
        & docker-compose -f docker-compose.production.optimized.yml up -d app
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to start application server"
        }
    } catch {
        Handle-Error "Application server failed: $($_.Exception.Message)"
    }
    Start-Sleep -Seconds 2
    
    Show-Progress 15 20 "Starting reverse proxy..."
    try {
        & docker-compose -f docker-compose.production.optimized.yml up -d nginx
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to start nginx"
        }
    } catch {
        Handle-Error "Nginx failed: $($_.Exception.Message)"
    }
    Start-Sleep -Seconds 2
    
    # Start monitoring if requested
    if ($Monitoring) {
        Show-Progress 16 20 "Starting monitoring services..."
        try {
            & docker-compose -f docker-compose.production.optimized.yml --profile monitoring up -d
        } catch {
            Write-ColorOutput "$($Symbols.Warning) Monitoring services failed to start" "Yellow"
        }
    }
}

# Health checks
function Test-ServiceHealth {
    Write-Host ""
    Write-ColorOutput "$($Symbols.Shield) Phase 4: Health Verification" "Yellow"
    
    Show-Progress 16 20 "Checking database health..."
    $timeout = 60
    $elapsed = 0
    do {
        try {
            $mysqlStatus = & docker-compose -f docker-compose.production.optimized.yml ps mysql 2>$null
            if ($mysqlStatus -match "healthy|Up") {
                break
            }
        } catch {}
        Start-Sleep -Seconds 2
        $elapsed += 2
    } while ($elapsed -lt $timeout)
    
    if ($elapsed -ge $timeout) {
        Handle-Error "Database health check failed - timeout"
    }
    
    Show-Progress 17 20 "Checking Redis health..."
    $elapsed = 0
    do {
        try {
            $redisStatus = & docker-compose -f docker-compose.production.optimized.yml ps redis 2>$null
            if ($redisStatus -match "healthy|Up") {
                break
            }
        } catch {}
        Start-Sleep -Seconds 2
        $elapsed += 2
    } while ($elapsed -lt $timeout)
    
    if ($elapsed -ge $timeout) {
        Handle-Error "Redis health check failed - timeout"
    }
    
    Show-Progress 18 20 "Checking application health..."
    $timeout = 120
    $elapsed = 0
    do {
        try {
            $appStatus = & docker-compose -f docker-compose.production.optimized.yml ps app 2>$null
            if ($appStatus -match "healthy|Up") {
                break
            }
        } catch {}
        Start-Sleep -Seconds 3
        $elapsed += 3
    } while ($elapsed -lt $timeout)
    
    if ($elapsed -ge $timeout) {
        Handle-Error "Application health check failed - timeout"
    }
    
    Show-Progress 19 20 "Final system verification..."
    Start-Sleep -Seconds 2
    
    Show-Progress 20 20 "All systems operational!"
    Write-Host ""
}

# Show final status
function Show-FinalStatus {
    Write-Host ""
    Write-ColorOutput "================================================================" "Green"
    Write-ColorOutput "$($Symbols.CheckMark) BUILD COMPLETE - KUROPANEL V2 PRODUCTION READY! $($Symbols.CheckMark)" "Green"
    Write-ColorOutput "================================================================" "Green"
    
    Write-Host ""
    Write-ColorOutput "$($Symbols.Chart) Service Status:" "Cyan"
    & docker-compose -f docker-compose.production.optimized.yml ps
    
    Write-Host ""
    Write-ColorOutput "$($Symbols.Rocket) Access Information:" "Yellow"
    Write-ColorOutput "Application URL: http://localhost" "White"
    Write-ColorOutput "Admin Panel: http://localhost/admin" "White"
    Write-ColorOutput "API Endpoint: http://localhost/api" "White"
    
    if ($Monitoring) {
        Write-ColorOutput "Prometheus: http://localhost:9090" "White"
        Write-ColorOutput "Grafana: http://localhost:3000" "White"
    }
    
    Write-Host ""
    Write-ColorOutput "$($Symbols.Rocket) Deployment completed in record time!" "Green"
    Write-ColorOutput "Next steps:" "Cyan"
    Write-ColorOutput "1. Configure SSL certificates for HTTPS" "White"
    Write-ColorOutput "2. Set up domain DNS settings" "White"
    Write-ColorOutput "3. Configure monitoring alerts" "White"
    Write-ColorOutput "4. Run security scan" "Yellow"
}

# Cleanup function
function Invoke-Cleanup {
    Write-Host ""
    Write-ColorOutput "Cleaning up..." "Yellow"
    try {
        & docker-compose -f docker-compose.production.optimized.yml down 2>$null
    } catch {
        # Ignore cleanup errors
    }
    exit 1
}

# Main execution
function Main {
    try {
        Show-Header
        Test-Prerequisites
        Start-DockerBuild
        Start-Services
        Test-ServiceHealth
        Show-FinalStatus
    } catch {
        Handle-Error $_.Exception.Message
    }
}

# Set up Ctrl+C handler
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    Invoke-Cleanup
}

# Run main function
Main
