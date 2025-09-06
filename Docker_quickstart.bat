@echo off
REM Quick Start Script for xsukax Ollama WebUI Docker (Windows)
REM This script automates the Docker setup and deployment

setlocal enabledelayedexpansion

REM Configuration
set IMAGE_NAME=xsukax-ollama-webui
set CONTAINER_NAME=ollama-webui
set PORT=3553

REM Display header
echo ========================================
echo    xsukax Ollama WebUI Docker Setup
echo ========================================
echo.

REM Check Docker installation
echo Checking Docker installation...
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker is not installed or not in PATH
    echo Please install Docker Desktop for Windows
    echo Visit: https://docs.docker.com/desktop/install/windows-install/
    pause
    exit /b 1
)
echo [OK] Docker is installed

REM Check if Docker is running
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker daemon is not running
    echo Please start Docker Desktop
    pause
    exit /b 1
)
echo [OK] Docker daemon is running

REM Check required files
echo Checking required files...
set "missing_files="
if not exist "index.html" set "missing_files=!missing_files! index.html"
if not exist "Dockerfile" set "missing_files=!missing_files! Dockerfile"
if not exist "nginx.conf" set "missing_files=!missing_files! nginx.conf"
if not exist "default.conf" set "missing_files=!missing_files! default.conf"

if not "!missing_files!"=="" (
    echo ERROR: Missing required files:!missing_files!
    echo Please ensure all Docker files are in the current directory
    pause
    exit /b 1
)
echo [OK] All required files are present

REM Check Ollama
echo Checking Ollama installation...
where ollama >nul 2>&1
if %errorlevel% neq 0 (
    echo WARNING: Ollama is not installed or not in PATH
    echo Visit: https://ollama.ai to install Ollama
    echo The container won't be able to connect to Ollama without it
    set /p continue="Continue anyway? (y/n): "
    if /i not "!continue!"=="y" (
        exit /b 1
    )
) else (
    echo [OK] Ollama is installed
    
    REM Check if Ollama is running
    curl -s http://localhost:11434/api/tags >nul 2>&1
    if %errorlevel% neq 0 (
        echo Starting Ollama with CORS enabled...
        start /b cmd /c "set OLLAMA_ORIGINS=* && ollama serve"
        timeout /t 3 /nobreak >nul
        echo [OK] Ollama started with CORS enabled
    ) else (
        echo [OK] Ollama is running
    )
)

REM Check port availability
echo Checking port %PORT% availability...
netstat -an | findstr :%PORT% | findstr LISTENING >nul 2>&1
if %errorlevel% equ 0 (
    echo WARNING: Port %PORT% is already in use
    set /p stopservice="Stop the service using port %PORT%? (y/n): "
    if /i "!stopservice!"=="y" (
        for /f "tokens=*" %%i in ('docker ps -q --filter "publish=%PORT%"') do (
            docker stop %%i >nul 2>&1
        )
        echo [OK] Port %PORT% is now available
    ) else (
        echo ERROR: Cannot continue with port %PORT% in use
        pause
        exit /b 1
    )
) else (
    echo [OK] Port %PORT% is available
)

REM Stop existing container if exists
echo Checking for existing container...
docker ps -a | findstr %CONTAINER_NAME% >nul 2>&1
if %errorlevel% equ 0 (
    echo Stopping existing container...
    docker stop %CONTAINER_NAME% >nul 2>&1
    docker rm %CONTAINER_NAME% >nul 2>&1
    echo [OK] Existing container removed
)

REM Build Docker image
echo Building Docker image...
docker build -t %IMAGE_NAME%:latest . >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Failed to build Docker image
    echo Run 'docker build -t %IMAGE_NAME%:latest .' to see detailed error
    pause
    exit /b 1
)
echo [OK] Docker image built successfully

REM Run container
echo Starting container...
docker run -d ^
    --name %CONTAINER_NAME% ^
    -p %PORT%:80 ^
    --add-host=host.docker.internal:host-gateway ^
    --restart unless-stopped ^
    %IMAGE_NAME%:latest >nul 2>&1

if %errorlevel% neq 0 (
    echo ERROR: Failed to start container
    echo Run 'docker logs %CONTAINER_NAME%' to see detailed error
    pause
    exit /b 1
)
echo [OK] Container started successfully

REM Wait for application to be ready
echo Waiting for application to be ready...
set attempts=0
:healthcheck
if %attempts% geq 30 (
    echo ERROR: Application health check timed out
    pause
    exit /b 1
)
curl -s -f http://localhost:%PORT%/health >nul 2>&1
if %errorlevel% neq 0 (
    timeout /t 1 /nobreak >nul
    set /a attempts+=1
    goto healthcheck
)
echo [OK] Application is healthy

REM Display success information
echo.
echo ========================================
echo    Deployment Successful!
echo ========================================
echo.
echo Access the application at:
echo   http://localhost:%PORT%
echo.
echo Useful commands:
echo   docker logs %CONTAINER_NAME%        - View logs
echo   docker stop %CONTAINER_NAME%        - Stop container
echo   docker start %CONTAINER_NAME%       - Start container
echo   docker restart %CONTAINER_NAME%     - Restart container
echo.
echo Ollama Configuration:
echo   Ensure Ollama is running with: set OLLAMA_ORIGINS=* ^&^& ollama serve
echo.

REM Ask to open browser
set /p openbrowser="Open browser now? (y/n): "
if /i "%openbrowser%"=="y" (
    start http://localhost:%PORT%
)

pause