# KuroPanel Docker Fix Script
# This script will rebuild the containers to fix CodeIgniter 4 and phpMyAdmin issues

Write-Host "=========================================" -ForegroundColor Green
Write-Host "  FIXING KUROPANEL DOCKER ISSUES" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Step 1: Stopping existing containers..." -ForegroundColor Yellow
docker-compose -f docker-compose.simple.yml down

Write-Host ""
Write-Host "Step 2: Rebuilding containers with CodeIgniter 4..." -ForegroundColor Yellow
docker-compose -f docker-compose.simple.yml build --no-cache

Write-Host ""
Write-Host "Step 3: Starting services..." -ForegroundColor Yellow
docker-compose -f docker-compose.simple.yml up -d

Write-Host ""
Write-Host "Step 4: Waiting for services to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

Write-Host ""
Write-Host "Step 5: Checking service status..." -ForegroundColor Yellow
docker-compose -f docker-compose.simple.yml ps

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "  SETUP COMPLETE!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 KuroPanel Application: http://localhost" -ForegroundColor White
Write-Host "🗄️  phpMyAdmin:           http://localhost:8080" -ForegroundColor White
Write-Host ""
Write-Host "📱 KuroPanel Login:" -ForegroundColor Cyan
Write-Host "   Username: admin" -ForegroundColor Gray
Write-Host "   Password: admin123" -ForegroundColor Gray
Write-Host ""
Write-Host "🗄️  Database Access:" -ForegroundColor Cyan
Write-Host "   Host: localhost:3306" -ForegroundColor Gray
Write-Host "   Database: kuro_db" -ForegroundColor Gray
Write-Host "   Username: root" -ForegroundColor Gray
Write-Host "   Password: rootpass" -ForegroundColor Gray
Write-Host ""
Write-Host "If you still see errors, check the logs with:" -ForegroundColor Yellow
Write-Host "docker-compose -f docker-compose.simple.yml logs -f app" -ForegroundColor Gray
