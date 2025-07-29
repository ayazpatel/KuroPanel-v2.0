param(
    [switch]$RemoveImages,
    [switch]$SkipTests,
    [switch]$Verbose,
    [switch]$Help
)

function Write-Header {
    param([string]$Title)
    Write-Host "=======================================" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "=======================================" -ForegroundColor Cyan
}

function Write-Step {
    param([string]$Step, [string]$Message)
    Write-Host "[$Step] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "  ✓ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "  ⚠ $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "  ✗ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "  → $Message" -ForegroundColor Cyan
}

function Show-Usage {
    Write-Host "KuroPanel Local Docker Test Script" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Usage: .\localDockerTest.ps1 [options]" -ForegroundColor Green
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Green
    Write-Host "  -RemoveImages  Remove old Docker images (slower but more thorough)"
    Write-Host "  -SkipTests     Skip running tests after setup"
    Write-Host "  -Verbose       Show detailed output"
    Write-Host "  -Help          Show this help message"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Magenta
    Write-Host "  .\localDockerTest.ps1                    # Standard fresh test"
    Write-Host "  .\localDockerTest.ps1 -RemoveImages      # Full cleanup with image removal"
    Write-Host "  .\localDockerTest.ps1 -SkipTests         # Setup only, no tests"
    Write-Host "  .\localDockerTest.ps1 -Verbose           # Detailed output"
}

function Test-ServiceHealth {
    param(
        [string]$ServiceName,
        [string]$Url,
        [int]$MaxAttempts = 20,
        [int]$DelaySeconds = 2
    )
    
    Write-Info "Checking $ServiceName..."
    
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Write-Success "$ServiceName is ready"
                return $true
            }
        }
        catch {
            if ($Verbose) {
                Write-Host "    Attempt $attempt/$MaxAttempts failed: $($_.Exception.Message)" -ForegroundColor DarkGray
            }
        }
        
        if ($attempt -lt $MaxAttempts) {
            Start-Sleep -Seconds $DelaySeconds
        }
    }
    
    Write-Warning "$ServiceName check timed out after $MaxAttempts attempts"
    return $false
}

function Test-DatabaseConnection {
    Write-Info "Checking database connection..."
    
    try {
        $result = & docker-compose exec -T database mysqladmin ping -h localhost -u kuro_user -pkuro_password 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Database connection successful"
            return $true
        }
    }
    catch {
        # Ignore errors for now
    }
    
    Write-Warning "Database connection check failed"
    return $false
}

function Remove-Containers {
    param([string[]]$Containers)
    
    Write-Step "1/6" "Stopping existing containers..."
    
    foreach ($container in $Containers) {
        & docker stop $container 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Stopped: $container"
        } else {
            Write-Host "  - Not running: $container" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    Write-Step "2/6" "Removing existing containers..."
    
    foreach ($container in $Containers) {
        & docker rm $container 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Removed: $container"
        } else {
            Write-Host "  - Not found: $container" -ForegroundColor Gray
        }
    }
}

function Remove-Images {
    param([string[]]$Images)
    
    Write-Host ""
    Write-Step "Optional" "Removing old images..."
    
    foreach ($image in $Images) {
        & docker rmi $image 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Removed image: $image"
        } else {
            Write-Host "  - Image not found: $image" -ForegroundColor Gray
        }
    }
}

function Remove-Volumes {
    param([string[]]$Volumes)
    
    Write-Host ""
    Write-Step "3/6" "Removing volumes for fresh data..."
    
    foreach ($volume in $Volumes) {
        & docker volume rm $volume 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Removed volume: $volume"
        } else {
            Write-Host "  - Volume not found: $volume" -ForegroundColor Gray
        }
    }
}

function Remove-Networks {
    param([string[]]$Networks)
    
    Write-Host ""
    Write-Step "4/6" "Cleaning up networks..."
    
    foreach ($network in $Networks) {
        & docker network rm $network 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Removed network: $network"
        } else {
            Write-Host "  - Network not found or in use: $network" -ForegroundColor Gray
        }
    }
}

# Main execution
if ($Help) {
    Show-Usage
    exit 0
}

Write-Header "KuroPanel Local Docker Test Script"

# Configuration
$ProjectName = "kuropanel"
$Containers = @(
    "${ProjectName}_app",
    "${ProjectName}_db", 
    "${ProjectName}_phpmyadmin",
    "${ProjectName}_test"
)
$Images = @(
    "${ProjectName}_app",
    "${ProjectName}_database",
    "${ProjectName}_phpmyadmin", 
    "${ProjectName}_test"
)
$Volumes = @("${ProjectName}_db_data")
$Networks = @("${ProjectName}_kuropanel")

Write-Host "Starting fresh Docker test environment..." -ForegroundColor Yellow
Write-Host ""

try {
    # Step 1 & 2: Remove containers
    Remove-Containers -Containers $Containers
    
    # Optional: Remove images
    if ($RemoveImages) {
        Remove-Images -Images $Images
    }
    
    # Step 3: Remove volumes
    Remove-Volumes -Volumes $Volumes
    
    # Step 4: Remove networks
    Remove-Networks -Networks $Networks
    
    # Step 5: Setup test environment
    Write-Host ""
    Write-Step "5/6" "Setting up test environment..."
    
    if (Test-Path ".env.testing") {
        Copy-Item ".env.testing" ".env" -Force
        Write-Success "Test environment configured"
    } else {
        Write-Warning ".env.testing not found, using current .env"
    }
    
    # Step 6: Build and start fresh containers
    Write-Host ""
    Write-Step "6/6" "Building and starting fresh containers..."
    
    Write-Info "Building containers (this may take a few minutes)..."
    if ($Verbose) {
        & docker-compose build --no-cache --parallel
    } else {
        & docker-compose build --no-cache --parallel 2>$null | Out-Null
    }
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Build failed!"
        exit 1
    }
    Write-Success "Build completed successfully"
    
    Write-Info "Starting services..."
    & docker-compose up -d
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to start services!"
        exit 1
    }
    Write-Success "Services started successfully"
    
    # Wait for services to be ready
    Write-Host ""
    Write-Host "Waiting for services to be ready..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    
    # Health checks
    Write-Host ""
    Write-Host "Performing health checks..." -ForegroundColor Yellow
    $appHealthy = Test-ServiceHealth -ServiceName "Application" -Url "http://localhost:8080" -MaxAttempts 30
    $pmaHealthy = Test-ServiceHealth -ServiceName "phpMyAdmin" -Url "http://localhost:8081" -MaxAttempts 15
    $dbHealthy = Test-DatabaseConnection
    
    # Run tests (unless skipped)
    $testResult = 0
    if (-not $SkipTests) {
        Write-Host ""
        Write-Host "Running test suite..." -ForegroundColor Yellow
        
        Write-Info "Building test container..."
        & docker-compose --profile testing build test --no-cache
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Test container build failed!"
            exit 1
        }
        
        Write-Info "Running tests..."
        & docker-compose --profile testing run --rm test ./vendor/bin/phpunit --testdox
        $testResult = $LASTEXITCODE
    }
    
    # Restore original environment
    if (Test-Path ".env.development") {
        Copy-Item ".env.development" ".env" -Force
        Write-Success "Development environment restored"
    }
    
    # Final status
    Write-Host ""
    Write-Header "Results"
    
    if ($SkipTests -or $testResult -eq 0) {
        if ($SkipTests) {
            Write-Host "🎉 FRESH DOCKER ENVIRONMENT READY!" -ForegroundColor Green
        } else {
            Write-Host "🎉 ALL TESTS PASSED!" -ForegroundColor Green
        }
        Write-Host "📊 Fresh Docker environment is ready" -ForegroundColor Green
        Write-Host ""
        Write-Host "Services available at:" -ForegroundColor Cyan
        Write-Host "• Application: http://localhost:8080" -ForegroundColor White
        Write-Host "• phpMyAdmin:  http://localhost:8081" -ForegroundColor White  
        Write-Host "• Database:    localhost:3306" -ForegroundColor White
    } else {
        Write-Host "❌ TESTS FAILED!" -ForegroundColor Red
        Write-Host "Check the test output above for details" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Current container status:" -ForegroundColor Yellow
    & docker-compose ps
    
    exit $testResult
}
catch {
    Write-Host ""
    Write-Header "ERROR"
    Write-Host "❌ Docker test setup failed!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting tips:" -ForegroundColor Yellow
    Write-Host "1. Check if Docker Desktop is running"
    Write-Host "2. Ensure ports 8080, 8081, 3306 are available"
    Write-Host "3. Check Docker logs: docker-compose logs"
    Write-Host "4. Try manual cleanup: docker system prune -a"
    Write-Host "5. Run with -Verbose for detailed output"
    
    exit 1
}
