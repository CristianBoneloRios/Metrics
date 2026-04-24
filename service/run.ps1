# run.ps1 - Levantar servicio CODSP

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Servicio CODSP Integracion - Cristian Bonelo" -ForegroundColor Yellow
Write-Host "Team: observabilidad | Project: onboarding-qas" -ForegroundColor Green
Write-Host "Puerto: 8080" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Set-Location $PSScriptRoot

Write-Host "Verificando Python..." -ForegroundColor Yellow
py --version 2>$null

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Python no está instalado o no está en el PATH" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Instalando dependencias..." -ForegroundColor Yellow
py -m pip install -r requirements.txt --trusted-host pypi.org --trusted-host files.pythonhosted.org

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Falló la instalación de dependencias" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Iniciando servicio..." -ForegroundColor Green
Write-Host "Metrics: http://localhost:8080/metrics" -ForegroundColor White
Write-Host "Health: http://localhost:8080/health" -ForegroundColor White
Write-Host ""

py main.py
