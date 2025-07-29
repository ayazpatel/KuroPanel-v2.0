param(
    [Parameter(Position=0)]
    [ValidateSet("build", "start", "stop", "restart", "test", "logs", "clean", "shell", "")]
    [string]$Action = "",
    
    [Parameter(Position=1)]
    [ValidateSet("dev", "test", "")]
    [string]$Environment = "dev"
)

function Write-Header {
    param([string]$Title)
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
}

function Show-Usage {
    Write-Host "Usage: .\build.ps1 [action] [environment]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Actions:" -ForegroundColor Green
    Write-Host "  build       - Build Docker containers"
    Write-Host "  start       - Start services"
    Write-Host "  stop        - Stop services"
    Write-Host "  restart     - Restart services"
    Write-Host "  test        - Run tests"
    Write-Host "  logs        - Show logs"
    Write-Host "  clean       - Clean up containers and volumes"
    Write-Host "  shell       - Open shell in app container"
    Write-Host ""
    Write-Host "Environments:" -ForegroundColor Green
    Write-Host "  dev         - Development (default)"
    Write-Host "  test        - Testing"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Magenta
    Write-Host "  .\build.ps1 build dev"
    Write-Host "  .\build.ps1 test"
    Write-Host "  .\build.ps1 start"
}

Write-Header "KuroPanel Docker Build Script"

if ($Action -eq "") {
    Show-Usage
    exit
}

# Set environment file based on parameter
$EnvFile = switch ($Environment) {
    "dev" { ".env.development" }
    "test" { ".env.testing" }
    default { ".env.development" }
}

Write-Host "Using environment: $Environment" -ForegroundColor Yellow
Write-Host "Environment file: $EnvFile" -ForegroundColor Yellow

# Copy appropriate environment file
if (Test-Path $EnvFile) {
    Copy-Item $EnvFile ".env" -Force
    Write-Host "Environment file copied successfully." -ForegroundColor Green
} else {
    Write-Warning "Environment file $EnvFile not found. Using default .env"
}

# Execute the requested action
switch ($Action) {
    "build" {
        Write-Host "Building Docker containers..." -ForegroundColor Blue
        & docker-compose build --no-cache
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Build failed!"
            exit $LASTEXITCODE
        }
        Write-Host "Build completed successfully!" -ForegroundColor Green
    }
    
    "start" {
        Write-Host "Starting services..." -ForegroundColor Blue
        & docker-compose up -d
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to start services!"
            exit $LASTEXITCODE
        }
        Write-Host "Services started successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Application: http://localhost:8080" -ForegroundColor Cyan
        Write-Host "phpMyAdmin: http://localhost:8081" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Use '.\build.ps1 logs' to view logs" -ForegroundColor Yellow
    }
    
    "stop" {
        Write-Host "Stopping services..." -ForegroundColor Blue
        & docker-compose down
        Write-Host "Services stopped." -ForegroundColor Green
    }
    
    "restart" {
        Write-Host "Restarting services..." -ForegroundColor Blue
        & docker-compose restart
        Write-Host "Services restarted." -ForegroundColor Green
    }
    
    "test" {
        Write-Host "Running tests..." -ForegroundColor Blue
        Write-Host "Copying test environment..." -ForegroundColor Yellow
        Copy-Item ".env.testing" ".env" -Force

        # Build test container if it doesn't exist
        & docker-compose --profile testing build test

        # Run tests
        & docker-compose --profile testing run --rm test ./vendor/bin/phpunit
        $TestResult = $LASTEXITCODE

        # Restore original environment
        if (Test-Path ".env.development") {
            Copy-Item ".env.development" ".env" -Force
        }

        if ($TestResult -ne 0) {
            Write-Error "Tests failed!"
            exit $TestResult
        } else {
            Write-Host "All tests passed!" -ForegroundColor Green
        }
    }
    
    "logs" {
        Write-Host "Showing logs... (Press Ctrl+C to exit)" -ForegroundColor Blue
        & docker-compose logs -f
    }
    
    "clean" {
        Write-Host "Cleaning up containers and volumes..." -ForegroundColor Blue
        $Confirm = Read-Host "This will remove all containers, networks, and volumes. Continue? (y/N)"
        if ($Confirm -ne "y" -and $Confirm -ne "Y") {
            Write-Host "Cancelled." -ForegroundColor Yellow
            return
        }

        & docker-compose down -v --remove-orphans
        & docker system prune -f
        Write-Host "Cleanup completed." -ForegroundColor Green
    }
    
    "shell" {
        Write-Host "Opening shell in app container..." -ForegroundColor Blue
        & docker-compose exec app bash
    }
    
    default {
        Write-Error "Invalid action: $Action"
        Show-Usage
    }
}
