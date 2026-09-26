@echo off
REM Unit Converter EKS Deployment Script (PowerShell)
REM This script deploys the Unit Converter application to EKS without Helm

setlocal enabledelayedexpansion

REM Configuration
set NAMESPACE=unit-converter
set DEPLOYMENT_NAME=unit-converter-app
set SERVICE_NAME=unit-converter-service
set KUBE_MANIFEST_DIR=k8s

REM Check if PowerShell is available
powershell -Command "Write-Host 'Checking PowerShell availability...'" >nul 2>&1
if errorlevel 1 (
    echo Error: PowerShell is required
    exit /b 1
)

REM Run the actual deployment using PowerShell
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$scriptPath = '%~dpn0.ps1'; " ^
    "if (-not (Test-Path $scriptPath)) { Write-Error 'PowerShell script not found'; exit 1 }; " ^
    ". $scriptPath; " ^
    "Deploy-UnitConverter -ImageUri '%1'"

exit /b %ERRORLEVEL%
