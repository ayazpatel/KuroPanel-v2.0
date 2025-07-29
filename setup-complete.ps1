# KuroPanel Complete Setup Script
# This script will build and run your complete KuroPanel setup with phpMyAdmin

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "    KuroPanel v2.0 - Complete Setup        " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "🚀 Starting complete setup..." -ForegroundColor Yellow

# Stop and remove existing containers
Write-Host "🔄 Cleaning up existing containers..." -ForegroundColor Yellow
docker-compose -f docker-compose.simple.yml down --remove-orphans
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Cleanup completed" -ForegroundColor Green
} else {
    Write-Host "⚠️  No existing containers to clean" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🏗️  Building and starting services..." -ForegroundColor Yellow

# Build and start all services
docker-compose -f docker-compose.simple.yml up --build -d

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host "    ✅ KuroPanel Setup Complete!            " -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "🌐 Your services are now running:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📱 KuroPanel Application:" -ForegroundColor White
    Write-Host "   URL: http://localhost" -ForegroundColor Green
    Write-Host "   Username: admin" -ForegroundColor Yellow
    Write-Host "   Password: admin123" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "🗄️  phpMyAdmin (Database Manager):" -ForegroundColor White
    Write-Host "   URL: http://localhost:8080" -ForegroundColor Green
    Write-Host "   Username: root" -ForegroundColor Yellow
    Write-Host "   Password: rootpass" -ForegroundColor Yellow
    Write-Host "   Database: kuropanel" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "📊 Database Information:" -ForegroundColor White
    Write-Host "   Host: localhost:3306" -ForegroundColor Cyan
    Write-Host "   Root Password: rootpass" -ForegroundColor Cyan
    Write-Host "   App User: kurouser" -ForegroundColor Cyan
    Write-Host "   App Password: kuropass" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "⚠️  SECURITY NOTICE:" -ForegroundColor Red
    Write-Host "   🔐 Change the default admin password after first login!" -ForegroundColor Red  
    Write-Host "   🔐 These are development credentials - change for production!" -ForegroundColor Red
    Write-Host ""
    
    Write-Host "📝 Quick Start:" -ForegroundColor Cyan
    Write-Host "   1. Open http://localhost in your browser" -ForegroundColor White
    Write-Host "   2. Login with admin/admin123" -ForegroundColor White
    Write-Host "   3. Change your password immediately" -ForegroundColor White
    Write-Host "   4. Start configuring your panel" -ForegroundColor White
    Write-Host ""
    
    Write-Host "🔧 Management Commands:" -ForegroundColor Cyan
    Write-Host "   Stop:    docker-compose -f docker-compose.simple.yml down" -ForegroundColor White
    Write-Host "   Restart: docker-compose -f docker-compose.simple.yml restart" -ForegroundColor White
    Write-Host "   Logs:    docker-compose -f docker-compose.simple.yml logs -f" -ForegroundColor White
    Write-Host ""
    
    # Wait a moment for containers to fully start
    Write-Host "⏳ Waiting for services to be ready..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    
    # Check container status
    Write-Host "📋 Container Status:" -ForegroundColor Cyan
    docker-compose -f docker-compose.simple.yml ps
    
    Write-Host ""
    Write-Host "🎉 Setup completed successfully!" -ForegroundColor Green
    Write-Host "   Your KuroPanel is ready to use!" -ForegroundColor Green
    
} else {
    Write-Host ""
    Write-Host "❌ Setup failed!" -ForegroundColor Red
    Write-Host "Please check the error messages above." -ForegroundColor Red
    Write-Host ""
    Write-Host "🔍 Troubleshooting:" -ForegroundColor Yellow
    Write-Host "   Check logs: docker-compose -f docker-compose.simple.yml logs" -ForegroundColor White
    Write-Host "   Check status: docker-compose -f docker-compose.simple.yml ps" -ForegroundColor White
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
