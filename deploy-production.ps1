# Production Build Script for KuroPanel V2
# PowerShell script for Windows production deployment

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("deploy", "update", "rollback", "backup", "health", "logs", "scale", "ssl", "monitor", "help")]
    [string]$Action = "help",
    
    [Parameter(Mandatory=$false)]
    [string]$Service = "",
    
    [Parameter(Mandatory=$false)]
    [int]$Replicas = 2,
    
    [Parameter(Mandatory=$false)]
    [string]$Domain = ""
)

# Configuration
$ProjectDir = Split-Path -Parent $PSScriptRoot
$EnvFile = Join-Path $ProjectDir ".env.production"
$BackupDir = Join-Path $ProjectDir "backups\deployment"
$LogFile = Join-Path $ProjectDir "deploy.log"
$ComposeFile = "docker-compose.production.yml"

# Colors for output
$Colors = @{
    Red = "Red"
    Green = "Green"
    Yellow = "Yellow"
    Blue = "Blue"
    White = "White"
}

# Logging functions
function Write-Log {
    param([string]$Message, [string]$Color = "Green")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] $Message"
    Write-Host $LogMessage -ForegroundColor $Color
    Add-Content -Path $LogFile -Value $LogMessage
}

function Write-Warning {
    param([string]$Message)
    Write-Log "WARNING: $Message" -Color "Yellow"
}

function Write-Error {
    param([string]$Message)
    Write-Log "ERROR: $Message" -Color "Red"
    exit 1
}

# Help function
function Show-Help {
    @"
KuroPanel V2 Production Deployment Script (PowerShell)

Usage: .\deploy-production.ps1 -Action <action> [parameters]

Actions:
    deploy          Full production deployment
    update          Update existing deployment
    rollback        Rollback to previous version
    backup          Create full backup
    health          Check system health
    logs            Show application logs
    scale           Scale services
    ssl             Setup SSL certificates
    monitor         Start monitoring services
    help            Show this help

Parameters:
    -Service        Service name (for logs, scale actions)
    -Replicas       Number of replicas (for scale action)
    -Domain         Domain name (for SSL setup)

Examples:
    .\deploy-production.ps1 -Action deploy
    .\deploy-production.ps1 -Action update
    .\deploy-production.ps1 -Action logs -Service app
    .\deploy-production.ps1 -Action scale -Service app -Replicas 3
    .\deploy-production.ps1 -Action ssl -Domain panel.example.com

"@ | Write-Host
}

# Pre-deployment checks
function Test-PreDeployment {
    Write-Log "Running pre-deployment checks..."
    
    # Check if running as Administrator
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Warning "Not running as Administrator. Some operations may fail."
    }
    
    # Check Docker
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Error "Docker is not installed or not in PATH"
    }
    
    if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
        Write-Error "Docker Compose is not installed or not in PATH"
    }
    
    # Check environment file
    if (-not (Test-Path $EnvFile)) {
        Write-Error "Production environment file not found: $EnvFile"
    }
    
    # Create required directories
    if (-not (Test-Path $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    }
    
    if (-not (Test-Path (Split-Path $LogFile))) {
        New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null
    }
    
    # Check disk space (require at least 5GB)
    $Drive = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq ($ProjectDir.Substring(0,2)) }
    $AvailableSpaceGB = [math]::Round($Drive.FreeSpace / 1GB, 2)
    $RequiredSpaceGB = 5
    
    if ($AvailableSpaceGB -lt $RequiredSpaceGB) {
        Write-Error "Insufficient disk space. Required: ${RequiredSpaceGB}GB, Available: ${AvailableSpaceGB}GB"
    }
    
    # Check memory (require at least 2GB)
    $TotalMemoryGB = [math]::Round((Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    $RequiredMemoryGB = 2
    
    if ($TotalMemoryGB -lt $RequiredMemoryGB) {
        Write-Warning "Low total memory. Required: ${RequiredMemoryGB}GB, Available: ${TotalMemoryGB}GB"
    }
    
    Write-Log "Pre-deployment checks completed successfully"
}

# Create backup
function New-Backup {
    Write-Log "Creating backup..."
    
    $BackupTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $BackupPath = Join-Path $BackupDir "backup_$BackupTimestamp"
    
    New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
    
    # Backup database
    $DbContainer = docker ps --format "table {{.Names}}" | Select-String "kuropanel_db_prod"
    if ($DbContainer) {
        Write-Log "Backing up database..."
        $MysqlRootPassword = (Get-Content $EnvFile | Select-String "MYSQL_ROOT_PASSWORD=" | ForEach-Object { $_.ToString().Split('=')[1] })
        docker exec kuropanel_db_prod mysqldump -u root -p"$MysqlRootPassword" --all-databases | Out-File -FilePath "$BackupPath\database.sql" -Encoding UTF8
    }
    
    # Backup application data
    Write-Log "Backing up application data..."
    $DataPath = Join-Path $ProjectDir "data"
    $SslPath = Join-Path $ProjectDir "ssl"
    
    if (Test-Path $DataPath) {
        Copy-Item -Path $DataPath -Destination $BackupPath -Recurse -Force
    }
    
    if (Test-Path $SslPath) {
        Copy-Item -Path $SslPath -Destination $BackupPath -Recurse -Force
    }
    
    if (Test-Path $EnvFile) {
        Copy-Item -Path $EnvFile -Destination $BackupPath -Force
    }
    
    # Create archive
    $ArchivePath = "$BackupPath.zip"
    Compress-Archive -Path "$BackupPath\*" -DestinationPath $ArchivePath -Force
    Remove-Item -Path $BackupPath -Recurse -Force
    
    Write-Log "Backup created: $ArchivePath"
    Set-Content -Path (Join-Path $ProjectDir ".last_backup") -Value $ArchivePath
}

# Deploy function
function Start-Deploy {
    Write-Log "Starting KuroPanel V2 production deployment..."
    
    Test-PreDeployment
    New-Backup
    
    Set-Location $ProjectDir
    
    # Pull latest images
    Write-Log "Pulling Docker images..."
    docker-compose -f $ComposeFile --env-file $EnvFile pull
    
    # Build custom images
    Write-Log "Building application images..."
    docker-compose -f $ComposeFile --env-file $EnvFile build --no-cache
    
    # Start services
    Write-Log "Starting services..."
    docker-compose -f $ComposeFile --env-file $EnvFile up -d
    
    # Wait for services to be ready
    Write-Log "Waiting for services to be ready..."
    Start-Sleep -Seconds 30
    
    # Run database migrations
    Write-Log "Running database setup..."
    docker-compose -f $ComposeFile --env-file $EnvFile exec -T app php spark migrate:latest
    
    # Health check
    if (Test-Health) {
        Write-Log "Deployment completed successfully!"
    } else {
        Write-Error "Deployment failed health check"
    }
}

# Update function
function Start-Update {
    Write-Log "Updating KuroPanel V2..."
    
    Test-PreDeployment
    New-Backup
    
    Set-Location $ProjectDir
    
    # Pull latest images
    Write-Log "Pulling updated images..."
    docker-compose -f $ComposeFile --env-file $EnvFile pull
    
    # Rebuild and restart services
    Write-Log "Rebuilding and restarting services..."
    docker-compose -f $ComposeFile --env-file $EnvFile up -d --build
    
    # Health check
    if (Test-Health) {
        Write-Log "Update completed successfully!"
    } else {
        Write-Error "Update failed health check"
    }
}

# Rollback function
function Start-Rollback {
    Write-Log "Rolling back KuroPanel V2..."
    
    $LastBackupFile = Join-Path $ProjectDir ".last_backup"
    if (-not (Test-Path $LastBackupFile)) {
        Write-Error "No backup found for rollback"
    }
    
    $BackupFile = Get-Content $LastBackupFile
    if (-not (Test-Path $BackupFile)) {
        Write-Error "Backup file not found: $BackupFile"
    }
    
    Set-Location $ProjectDir
    
    # Stop services
    Write-Log "Stopping services..."
    docker-compose -f $ComposeFile --env-file $EnvFile down
    
    # Restore backup
    Write-Log "Restoring from backup..."
    $RestoreDir = Join-Path $BackupDir "restore_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -ItemType Directory -Path $RestoreDir -Force | Out-Null
    Expand-Archive -Path $BackupFile -DestinationPath $RestoreDir -Force
    
    # Restore data
    $DataPath = Join-Path $ProjectDir "data"
    $SslPath = Join-Path $ProjectDir "ssl"
    $RestoreDataPath = Join-Path $RestoreDir "data"
    $RestoreSslPath = Join-Path $RestoreDir "ssl"
    
    if (Test-Path $RestoreDataPath) {
        if (Test-Path $DataPath) {
            Remove-Item -Path $DataPath -Recurse -Force
        }
        Copy-Item -Path $RestoreDataPath -Destination $DataPath -Recurse -Force
    }
    
    if (Test-Path $RestoreSslPath) {
        if (Test-Path $SslPath) {
            Remove-Item -Path $SslPath -Recurse -Force
        }
        Copy-Item -Path $RestoreSslPath -Destination $SslPath -Recurse -Force
    }
    
    # Restore database
    $DatabaseBackup = Join-Path $RestoreDir "database.sql"
    if (Test-Path $DatabaseBackup) {
        docker-compose -f $ComposeFile --env-file $EnvFile up -d database
        Start-Sleep -Seconds 10
        Get-Content $DatabaseBackup | docker exec -i kuropanel_db_prod mysql -u root -p"$MysqlRootPassword"
    }
    
    # Start services
    Write-Log "Starting services..."
    docker-compose -f $ComposeFile --env-file $EnvFile up -d
    
    # Cleanup
    Remove-Item -Path $RestoreDir -Recurse -Force
    
    Write-Log "Rollback completed successfully!"
}

# Health check function
function Test-Health {
    Write-Log "Performing health check..."
    
    $MaxAttempts = 30
    $Attempt = 1
    
    while ($Attempt -le $MaxAttempts) {
        try {
            $Response = Invoke-WebRequest -Uri "http://localhost/api/health" -UseBasicParsing -TimeoutSec 10
            if ($Response.StatusCode -eq 200) {
                Write-Log "Health check passed"
                return $true
            }
        } catch {
            Write-Log "Health check attempt $Attempt/$MaxAttempts failed, retrying..."
        }
        
        Start-Sleep -Seconds 10
        $Attempt++
    }
    
    Write-Error "Health check failed after $MaxAttempts attempts"
    return $false
}

# Show logs function
function Show-Logs {
    Set-Location $ProjectDir
    
    if ($Service) {
        docker-compose -f $ComposeFile --env-file $EnvFile logs -f $Service
    } else {
        docker-compose -f $ComposeFile --env-file $EnvFile logs -f
    }
}

# Scale services function
function Set-Scale {
    $ServiceName = if ($Service) { $Service } else { "app" }
    
    Write-Log "Scaling $ServiceName to $Replicas replicas..."
    
    Set-Location $ProjectDir
    docker-compose -f $ComposeFile --env-file $EnvFile up -d --scale "$ServiceName=$Replicas"
    
    Write-Log "Scaling completed"
}

# Setup SSL certificates
function Set-SSL {
    Write-Log "Setting up SSL certificates..."
    
    $DomainName = if ($Domain) { $Domain } else {
        (Get-Content $EnvFile | Select-String "DOMAIN=" | ForEach-Object { $_.ToString().Split('=')[1] })
    }
    
    $SslDir = Join-Path $ProjectDir "ssl"
    if (-not (Test-Path $SslDir)) {
        New-Item -ItemType Directory -Path $SslDir -Force | Out-Null
    }
    
    $CertFile = Join-Path $SslDir "fullchain.pem"
    $KeyFile = Join-Path $SslDir "privkey.pem"
    
    # Generate self-signed certificate if none exists
    if ((-not (Test-Path $CertFile)) -or (-not (Test-Path $KeyFile))) {
        Write-Log "Generating self-signed SSL certificate..."
        
        # Use OpenSSL if available, otherwise create a basic certificate
        if (Get-Command openssl -ErrorAction SilentlyContinue) {
            openssl req -x509 -newkey rsa:4096 -keyout $KeyFile -out $CertFile -days 365 -nodes -subj "/C=US/ST=State/L=City/O=Organization/CN=$DomainName"
        } else {
            Write-Warning "OpenSSL not found. Please install OpenSSL or manually place SSL certificates in the ssl directory."
        }
    }
    
    Write-Log "SSL certificates ready"
}

# Start monitoring services
function Start-Monitoring {
    Write-Log "Starting monitoring services..."
    
    Set-Location $ProjectDir
    docker-compose -f $ComposeFile --env-file $EnvFile --profile with-monitoring up -d
    
    Write-Log "Monitoring services started"
    Write-Log "Grafana: http://localhost:3000"
    Write-Log "Prometheus: http://localhost:9090"
}

# Main script logic
function Main {
    Set-Location $ProjectDir
    
    switch ($Action) {
        "deploy" { Start-Deploy }
        "update" { Start-Update }
        "rollback" { Start-Rollback }
        "backup" { New-Backup }
        "health" { Test-Health }
        "logs" { Show-Logs }
        "scale" { Set-Scale }
        "ssl" { Set-SSL }
        "monitor" { Start-Monitoring }
        "help" { Show-Help }
        default { 
            Write-Error "Unknown action: $Action. Use 'help' for available actions."
        }
    }
}

# Execute main function
try {
    Main
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
}
