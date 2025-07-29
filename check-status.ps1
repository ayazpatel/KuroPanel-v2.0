# KuroPanel Status Checker
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "      KuroPanel Status Check                " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
$dockerRunning = Get-Process "Docker Desktop" -ErrorAction SilentlyContinue
if ($dockerRunning) {
    Write-Host "✅ Docker Desktop is running" -ForegroundColor Green
} else {
    Write-Host "❌ Docker Desktop is not running" -ForegroundColor Red
    Write-Host "Please start Docker Desktop first." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "📋 Container Status:" -ForegroundColor Cyan
docker-compose -f docker-compose.simple.yml ps

Write-Host ""
Write-Host "🔗 Service URLs:" -ForegroundColor Cyan
Write-Host "   KuroPanel: http://localhost" -ForegroundColor Green
Write-Host "   phpMyAdmin: http://localhost:8080" -ForegroundColor Green

Write-Host ""
Write-Host "🔑 Default Credentials:" -ForegroundColor Yellow
Write-Host "   KuroPanel - Username: admin, Password: admin123" -ForegroundColor White
Write-Host "   phpMyAdmin - Username: root, Password: rootpass" -ForegroundColor White

Write-Host ""
Write-Host "📊 Quick Actions:" -ForegroundColor Cyan
Write-Host "   [1] View logs: docker-compose -f docker-compose.simple.yml logs -f" -ForegroundColor White
Write-Host "   [2] Restart: docker-compose -f docker-compose.simple.yml restart" -ForegroundColor White
Write-Host "   [3] Stop: docker-compose -f docker-compose.simple.yml down" -ForegroundColor White

Write-Host ""
