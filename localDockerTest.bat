@echo off
setlocal EnableDelayedExpansion

echo =======================================
echo   KuroPanel Local Docker Test Script
echo =======================================

set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

REM Configuration
set "PROJECT_NAME=kuropanel"
set "CONTAINERS=%PROJECT_NAME%_app %PROJECT_NAME%_db %PROJECT_NAME%_phpmyadmin %PROJECT_NAME%_test"
set "IMAGES=%PROJECT_NAME%_app %PROJECT_NAME%_database %PROJECT_NAME%_phpmyadmin %PROJECT_NAME%_test"
set "VOLUMES=%PROJECT_NAME%_db_data"
set "NETWORKS=%PROJECT_NAME%_kuropanel"

echo Starting fresh Docker test environment...
echo.

REM Step 1: Stop and remove existing containers
echo [1/6] Stopping existing containers...
for %%c in (%CONTAINERS%) do (
    docker stop %%c >nul 2>&1
    if !ERRORLEVEL! equ 0 (
        echo   ✓ Stopped: %%c
    ) else (
        echo   - Not running: %%c
    )
)

echo.
echo [2/6] Removing existing containers...
for %%c in (%CONTAINERS%) do (
    docker rm %%c >nul 2>&1
    if !ERRORLEVEL! equ 0 (
        echo   ✓ Removed: %%c
    ) else (
        echo   - Not found: %%c
    )
)

REM Step 2: Remove old images (optional, uncomment if needed)
REM echo.
REM echo [Optional] Removing old images...
REM for %%i in (%IMAGES%) do (
REM     docker rmi %%i >nul 2>&1
REM     if !ERRORLEVEL! equ 0 (
REM         echo   ✓ Removed image: %%i
REM     ) else (
REM         echo   - Image not found: %%i
REM     )
REM )

REM Step 3: Remove volumes (to ensure fresh database)
echo.
echo [3/6] Removing volumes for fresh data...
for %%v in (%VOLUMES%) do (
    docker volume rm %%v >nul 2>&1
    if !ERRORLEVEL! equ 0 (
        echo   ✓ Removed volume: %%v
    ) else (
        echo   - Volume not found: %%v
    )
)

REM Step 4: Clean up networks
echo.
echo [4/6] Cleaning up networks...
docker network rm %NETWORKS% >nul 2>&1
if !ERRORLEVEL! equ 0 (
    echo   ✓ Removed network: %NETWORKS%
) else (
    echo   - Network not found or in use: %NETWORKS%
)

REM Step 5: Set up test environment
echo.
echo [5/6] Setting up test environment...
if exist ".env.testing" (
    copy ".env.testing" ".env" >nul
    echo   ✓ Test environment configured
) else (
    echo   ⚠ Warning: .env.testing not found, using current .env
)

REM Step 6: Build and start fresh containers
echo.
echo [6/6] Building and starting fresh containers...
echo   → Building containers (this may take a few minutes)...
docker-compose build --no-cache --parallel
if %ERRORLEVEL% neq 0 (
    echo   ✗ Build failed!
    goto :error
)
echo   ✓ Build completed successfully

echo   → Starting services...
docker-compose up -d
if %ERRORLEVEL% neq 0 (
    echo   ✗ Failed to start services!
    goto :error
)
echo   ✓ Services started successfully

REM Wait for services to be ready
echo.
echo Waiting for services to be ready...
timeout /t 10 /nobreak >nul

REM Health check
echo.
echo Performing health checks...
call :check_service "Application" "http://localhost:8080" 30
call :check_service "phpMyAdmin" "http://localhost:8081" 15
call :check_database_connection

REM Run tests
echo.
echo Running test suite...
docker-compose --profile testing build test --no-cache
if %ERRORLEVEL% neq 0 (
    echo   ✗ Test container build failed!
    goto :error
)

docker-compose --profile testing run --rm test ./vendor/bin/phpunit --testdox
set "TEST_RESULT=%ERRORLEVEL%"

REM Restore original environment
if exist ".env.development" (
    copy ".env.development" ".env" >nul
    echo   ✓ Development environment restored
)

REM Final status
echo.
echo =======================================
if %TEST_RESULT% equ 0 (
    echo   🎉 ALL TESTS PASSED!
    echo   📊 Fresh Docker environment is ready
    echo.
    echo   Services available at:
    echo   • Application: http://localhost:8080
    echo   • phpMyAdmin:  http://localhost:8081
    echo   • Database:    localhost:3306
) else (
    echo   ❌ TESTS FAILED!
    echo   Check the test output above for details
)
echo =======================================
echo.

REM Show container status
echo Current container status:
docker-compose ps

exit /b %TEST_RESULT%

:check_service
set "service_name=%~1"
set "service_url=%~2"
set "max_attempts=%~3"
set "attempt=0"

echo   → Checking %service_name%...
:check_loop
set /a attempt+=1
curl -s -f %service_url% >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo   ✓ %service_name% is ready
    goto :eof
)
if %attempt% geq %max_attempts% (
    echo   ⚠ %service_name% check timed out after %max_attempts% attempts
    goto :eof
)
timeout /t 2 /nobreak >nul
goto :check_loop

:check_database_connection
echo   → Checking database connection...
docker-compose exec -T database mysqladmin ping -h localhost -u kuro_user -pkuro_password >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo   ✓ Database connection successful
) else (
    echo   ⚠ Database connection check failed
)
goto :eof

:error
echo.
echo =======================================
echo   ❌ ERROR: Docker test setup failed!
echo =======================================
echo.
echo Troubleshooting tips:
echo 1. Check if Docker Desktop is running
echo 2. Ensure ports 8080, 8081, 3306 are available
echo 3. Check Docker logs: docker-compose logs
echo 4. Try manual cleanup: docker system prune -a
echo.
exit /b 1
