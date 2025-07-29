@echo off
setlocal EnableDelayedExpansion

echo ================================
echo   KuroPanel Docker Build Script
echo ================================

set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

REM Parse command line arguments
set "ACTION=%1"
set "ENVIRONMENT=%2"

if "%ACTION%"=="" (
    echo Usage: build.bat [action] [environment]
    echo.
    echo Actions:
    echo   build       - Build Docker containers
    echo   start       - Start services
    echo   stop        - Stop services
    echo   restart     - Restart services
    echo   test        - Run tests
    echo   logs        - Show logs
    echo   clean       - Clean up containers and volumes
    echo   shell       - Open shell in app container
    echo.
    echo Environments:
    echo   dev         - Development ^(default^)
    echo   test        - Testing
    echo.
    echo Examples:
    echo   build.bat build dev
    echo   build.bat test
    echo   build.bat start
    goto :eof
)

if "%ENVIRONMENT%"=="" set "ENVIRONMENT=dev"

REM Set environment file based on parameter
if "%ENVIRONMENT%"=="dev" (
    set "ENV_FILE=.env.development"
) else if "%ENVIRONMENT%"=="test" (
    set "ENV_FILE=.env.testing"
) else (
    echo Invalid environment: %ENVIRONMENT%
    echo Valid options: dev, test
    goto :eof
)

echo Using environment: %ENVIRONMENT%
echo Environment file: %ENV_FILE%

REM Copy appropriate environment file
if exist "%ENV_FILE%" (
    copy "%ENV_FILE%" ".env" >nul
    echo Environment file copied successfully.
) else (
    echo Warning: Environment file %ENV_FILE% not found. Using default .env
)

REM Execute the requested action
if "%ACTION%"=="build" goto :build
if "%ACTION%"=="start" goto :start
if "%ACTION%"=="stop" goto :stop
if "%ACTION%"=="restart" goto :restart
if "%ACTION%"=="test" goto :test
if "%ACTION%"=="logs" goto :logs
if "%ACTION%"=="clean" goto :clean
if "%ACTION%"=="shell" goto :shell

echo Invalid action: %ACTION%
goto :eof

:build
echo Building Docker containers...
docker-compose build --no-cache
if %ERRORLEVEL% neq 0 (
    echo Build failed!
    goto :eof
)
echo Build completed successfully!
goto :eof

:start
echo Starting services...
docker-compose up -d
if %ERRORLEVEL% neq 0 (
    echo Failed to start services!
    goto :eof
)
echo Services started successfully!
echo.
echo Application: http://localhost:8080
echo phpMyAdmin: http://localhost:8081
echo.
echo Use 'build.bat logs' to view logs
goto :eof

:stop
echo Stopping services...
docker-compose down
echo Services stopped.
goto :eof

:restart
echo Restarting services...
docker-compose restart
echo Services restarted.
goto :eof

:test
echo Running tests...
echo Copying test environment...
copy ".env.testing" ".env" >nul

REM Build test container if it doesn't exist
docker-compose --profile testing build test

REM Run tests
docker-compose --profile testing run --rm test ./vendor/bin/phpunit
set "TEST_RESULT=%ERRORLEVEL%"

REM Restore original environment
if exist ".env.development" (
    copy ".env.development" ".env" >nul
)

if %TEST_RESULT% neq 0 (
    echo Tests failed!
    exit /b %TEST_RESULT%
) else (
    echo All tests passed!
)
goto :eof

:logs
echo Showing logs... (Press Ctrl+C to exit)
docker-compose logs -f
goto :eof

:clean
echo Cleaning up containers and volumes...
set /p "CONFIRM=This will remove all containers, networks, and volumes. Continue? (y/N): "
if /i not "%CONFIRM%"=="y" (
    echo Cancelled.
    goto :eof
)

docker-compose down -v --remove-orphans
docker system prune -f
echo Cleanup completed.
goto :eof

:shell
echo Opening shell in app container...
docker-compose exec app bash
goto :eof
