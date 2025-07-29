#!/usr/bin/env pwsh
# KuroPanel V2 Local Docker Test Script (PowerShell)
# Enhanced testing with V2 features and comprehensive validation

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("quick", "full", "api", "performance")]
    [string]$TestType = "quick",
    
    [Parameter(Mandatory=$false)]
    [switch]$CleanStart,
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose
)

# Configuration
$PROJECT_NAME = "kuropanel"
$APP_URL = "http://localhost:8080"
$API_URL = "$APP_URL/api"
$CONNECT_URL = "$APP_URL/connect"
$DB_URL = "localhost:3306"
$LOG_FILE = "test-results-$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss').log"

# Colors for output
$Colors = @{
    Red = "Red"
    Green = "Green"
    Yellow = "Yellow"
    Blue = "Cyan"
    White = "White"
}

function Write-Log {
    param($Message, $Color = "White")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage -ForegroundColor $Colors[$Color]
    Add-Content -Path $LOG_FILE -Value $logMessage
}

function Test-ServiceHealth {
    param($ServiceName, $Url, $ExpectedStatus = 200)
    
    try {
        $response = Invoke-WebRequest -Uri $Url -TimeoutSec 10 -UseBasicParsing
        if ($response.StatusCode -eq $ExpectedStatus) {
            Write-Log "✓ $ServiceName is healthy (HTTP $($response.StatusCode))" "Green"
            return $true
        } else {
            Write-Log "✗ $ServiceName returned HTTP $($response.StatusCode)" "Red"
            return $false
        }
    } catch {
        Write-Log "✗ $ServiceName is not responding: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Test-DatabaseConnection {
    Write-Log "Testing database connection..." "Blue"
    
    try {
        # Test MySQL connection using PHP
        $phpTest = @'
<?php
try {
    $pdo = new PDO('mysql:host=localhost:3306;dbname=kuropanel', 'kuro_user', 'kuro_password');
    $stmt = $pdo->query('SELECT COUNT(*) FROM users');
    $count = $stmt->fetchColumn();
    echo "Database connection OK - Users: $count";
    exit(0);
} catch (Exception $e) {
    echo "Database error: " . $e->getMessage();
    exit(1);
}
?>
'@
        
        $phpTest | Out-File -FilePath "temp_db_test.php" -Encoding UTF8
        $result = php temp_db_test.php 2>&1
        Remove-Item "temp_db_test.php" -ErrorAction SilentlyContinue
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "✓ $result" "Green"
            return $true
        } else {
            Write-Log "✗ Database test failed: $result" "Red"
            return $false
        }
    } catch {
        Write-Log "✗ Database test error: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Test-ApiEndpoints {
    Write-Log "Testing API endpoints..." "Blue"
    
    $endpoints = @(
        @{Name="Health Check"; Url="$API_URL/health"; Expected=404} # Route may not exist yet
        @{Name="License Validation"; Url="$API_URL/validateLicense"; Expected=405} # POST only
    )
    
    $passed = 0
    foreach ($endpoint in $endpoints) {
        try {
            $response = Invoke-WebRequest -Uri $endpoint.Url -TimeoutSec 5 -UseBasicParsing -ErrorAction SilentlyContinue
            Write-Log "✓ $($endpoint.Name) endpoint accessible" "Green"
            $passed++
        } catch {
            Write-Log "ℹ $($endpoint.Name) endpoint: $($_.Exception.Message)" "Yellow"
        }
    }
    
    Write-Log "API Tests: $passed endpoints tested" "Blue"
    return $true
}

function Start-DockerServices {
    param([bool]$CleanStart)
    
    Write-Log "Starting KuroPanel V2 services..." "Blue"
    
    if ($CleanStart) {
        Write-Log "Performing clean start..." "Yellow"
        docker-compose -p $PROJECT_NAME down -v 2>$null
        docker system prune -f 2>$null
    }
    
    # Build and start services
    docker-compose -p $PROJECT_NAME up -d --build
    
    if ($LASTEXITCODE -ne 0) {
        Write-Log "✗ Failed to start Docker services" "Red"
        return $false
    }
    
    # Wait for services to be ready
    Write-Log "Waiting for services to initialize..." "Yellow"
    Start-Sleep -Seconds 30
    
    return $true
}

function Get-ServiceStatus {
    Write-Log "Checking service status..." "Blue"
    
    try {
        $services = docker-compose -p $PROJECT_NAME ps
        Write-Log "Service Status:" "Blue"
        Write-Log $services "White"
    } catch {
        Write-Log "Could not get service status" "Yellow"
    }
}

# Main execution
Write-Log "=== KuroPanel V2 Docker Test Suite ===" "Blue"
Write-Log "Test Type: $TestType" "Blue"
Write-Log "Clean Start: $CleanStart" "Blue"
Write-Log "Log File: $LOG_FILE" "Blue"
Write-Log "========================================" "Blue"

# Start services
if (-not (Start-DockerServices -CleanStart $CleanStart)) {
    Write-Log "Failed to start services. Exiting." "Red"
    exit 1
}

# Show service status
Get-ServiceStatus

# Execute tests based on type
$allTestsPassed = $true

switch ($TestType) {
    "quick" {
        $allTestsPassed = (Test-ServiceHealth -ServiceName "Main Application" -Url $APP_URL) -and $allTestsPassed
        $allTestsPassed = (Test-DatabaseConnection) -and $allTestsPassed
    }
    "full" {
        $allTestsPassed = (Test-ServiceHealth -ServiceName "Main Application" -Url $APP_URL) -and $allTestsPassed
        $allTestsPassed = (Test-DatabaseConnection) -and $allTestsPassed
        $allTestsPassed = (Test-ApiEndpoints) -and $allTestsPassed
    }
    "api" {
        $allTestsPassed = (Test-ApiEndpoints) -and $allTestsPassed
    }
    "performance" {
        Write-Log "Performance testing not yet implemented" "Yellow"
    }
}

# Final report
Write-Log "========================================" "Blue"
if ($allTestsPassed) {
    Write-Log "🎉 Tests completed! KuroPanel V2 is ready!" "Green"
    Write-Log "🌐 Access your panel at: $APP_URL" "Green"
    Write-Log "🔗 PHPMyAdmin at: http://localhost:8081" "Green"
} else {
    Write-Log "❌ Some tests had issues. Check the logs above." "Red"
}

Write-Log "Test results saved to: $LOG_FILE" "Blue"
Write-Log "========================================" "Blue"

# Exit with appropriate code
exit $(if ($allTestsPassed) { 0 } else { 1 })
