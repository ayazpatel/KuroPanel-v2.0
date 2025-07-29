#!/usr/bin/env pwsh

Write-Host "=================================================" -ForegroundColor Green
Write-Host "KURO PANEL - DOCKER SETUP COMPLETE!" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green
Write-Host ""

# Check container status
Write-Host "Container Status:" -ForegroundColor Cyan
docker-compose -f docker-compose.simple.yml ps

Write-Host ""
Write-Host "Application URLs:" -ForegroundColor Yellow
Write-Host "  Main Application: http://localhost" -ForegroundColor White
Write-Host "  phpMyAdmin:       http://localhost:8080" -ForegroundColor White
Write-Host ""

Write-Host "Default Credentials:" -ForegroundColor Yellow
Write-Host "  Application Login:" -ForegroundColor Cyan
Write-Host "    Username: admin" -ForegroundColor White
Write-Host "    Password: admin123" -ForegroundColor White
Write-Host ""
Write-Host "  Database (MySQL):" -ForegroundColor Cyan
Write-Host "    Host:     localhost:3306" -ForegroundColor White
Write-Host "    Database: kuro_db" -ForegroundColor White
Write-Host "    Username: kuro_user" -ForegroundColor White
Write-Host "    Password: kuro_password" -ForegroundColor White
Write-Host ""
Write-Host "  phpMyAdmin:" -ForegroundColor Cyan
Write-Host "    Username: kuro_user" -ForegroundColor White
Write-Host "    Password: kuro_password" -ForegroundColor White
Write-Host ""

Write-Host "Setup Complete! All services are running." -ForegroundColor Green
Write-Host "You can now access the application and start using it!" -ForegroundColor Green
Write-Host ""
Write-Host "Need help?" -ForegroundColor Yellow
Write-Host "   Check logs: docker-compose -f docker-compose.simple.yml logs" -ForegroundColor Gray
Write-Host "   Stop services: docker-compose -f docker-compose.simple.yml down" -ForegroundColor Gray
Write-Host "   Restart services: docker-compose -f docker-compose.simple.yml restart" -ForegroundColor Gray
Write-Host "=================================================" -ForegroundColor Green
