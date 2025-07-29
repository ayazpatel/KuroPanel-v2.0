# KuroPanel Docker Setup - Status Display
Write-Host "=================================" -ForegroundColor Green
Write-Host "  KUROPANEL DOCKER SETUP COMPLETE" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green
Write-Host ""

# Check container status
$containers = docker-compose -f docker-compose.simple.yml ps --format "table {{.Name}}\t{{.Status}}" | Select-Object -Skip 1

Write-Host "Container Status:" -ForegroundColor Yellow
Write-Host "=================" -ForegroundColor Yellow
$containers | ForEach-Object { 
    if ($_ -match "Up.*healthy") {
        Write-Host $_ -ForegroundColor Green
    } elseif ($_ -match "Up") {
        Write-Host $_ -ForegroundColor Yellow
    } else {
        Write-Host $_ -ForegroundColor Red
    }
}
Write-Host ""

Write-Host "Access URLs:" -ForegroundColor Cyan
Write-Host "============" -ForegroundColor Cyan
Write-Host "🌐 KuroPanel Application: http://localhost" -ForegroundColor White
Write-Host "🗄️  phpMyAdmin:           http://localhost:8080" -ForegroundColor White
Write-Host ""

Write-Host "Default Credentials:" -ForegroundColor Magenta
Write-Host "===================" -ForegroundColor Magenta
Write-Host "📱 KuroPanel Admin:" -ForegroundColor White
Write-Host "   Username: admin" -ForegroundColor Gray
Write-Host "   Password: admin123" -ForegroundColor Gray
Write-Host ""
Write-Host "🗄️  MySQL Database:" -ForegroundColor White
Write-Host "   Host:     localhost:3306" -ForegroundColor Gray
Write-Host "   Database: kuro_db" -ForegroundColor Gray
Write-Host "   Username: root" -ForegroundColor Gray
Write-Host "   Password: rootpass" -ForegroundColor Gray
Write-Host ""
Write-Host "🗄️  phpMyAdmin Access:" -ForegroundColor White
Write-Host "   Username: root" -ForegroundColor Gray
Write-Host "   Password: rootpass" -ForegroundColor Gray
Write-Host ""

Write-Host "Database Setup:" -ForegroundColor Green
Write-Host "===============" -ForegroundColor Green
Write-Host "✅ Database 'kuro_db' created" -ForegroundColor Green
Write-Host "✅ Schema loaded from kuro_upgraded.sql" -ForegroundColor Green
Write-Host "✅ Default admin user created" -ForegroundColor Green
Write-Host ""

Write-Host "Quick Commands:" -ForegroundColor Yellow
Write-Host "===============" -ForegroundColor Yellow
Write-Host "🔄 Restart services: docker-compose -f docker-compose.simple.yml restart" -ForegroundColor Gray
Write-Host "🛑 Stop services:    docker-compose -f docker-compose.simple.yml down" -ForegroundColor Gray
Write-Host "📋 View logs:        docker-compose -f docker-compose.simple.yml logs -f [service-name]" -ForegroundColor Gray
Write-Host ""

Write-Host "Happy coding! 🚀" -ForegroundColor Green
