# Simple Build Script for KuroPanel
# Just builds and runs the basic setup

Write-Host "Starting simple KuroPanel build..." -ForegroundColor Green

# Check if Docker is running
try {
    docker --version | Out-Null
    Write-Host "✓ Docker is available" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker is not available. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

# Stop any existing containers
Write-Host "Stopping existing containers..." -ForegroundColor Yellow
docker-compose -f docker-compose.simple.yml down 2>$null

# Build and start services
Write-Host "Building and starting services..." -ForegroundColor Yellow
docker-compose -f docker-compose.simple.yml up --build -d

# Check if services are running
Write-Host "Checking services..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

$services = docker-compose -f docker-compose.simple.yml ps
Write-Host "Service Status:" -ForegroundColor Cyan
Write-Host $services

Write-Host ""
Write-Host "✓ Setup complete!" -ForegroundColor Green
Write-Host "📌 Access your application at: http://localhost" -ForegroundColor Cyan
Write-Host "📌 MySQL is available at: localhost:3306" -ForegroundColor Cyan
Write-Host "   Database: kuropanel" -ForegroundColor White
Write-Host "   Username: root" -ForegroundColor White
Write-Host "   Password: rootpass" -ForegroundColor White
Write-Host ""
Write-Host "To stop: docker-compose -f docker-compose.simple.yml down" -ForegroundColor Yellow
