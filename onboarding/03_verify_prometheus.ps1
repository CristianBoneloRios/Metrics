# 03_verify_prometheus.ps1 - Verificar target en Prometheus
param(
    [string]$PrometheusUrl = "http://10.164.10.137:9090",
    [string]$JobName = "servicio-codsp-integracion"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Verificando Target en Prometheus QAS" -ForegroundColor Yellow
Write-Host "Cristian Bonelo - onboarding-qas" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`n[INFO] Buscando job: $JobName" -ForegroundColor Cyan

# Verificar targets activos
try {
    $targetsResponse = Invoke-RestMethod -Uri "$PrometheusUrl/api/v1/targets?state=active" -Method Get
    
    $target = $targetsResponse.data.activeTargets | Where-Object { $_.labels.job -eq $JobName }
    
    if ($target) {
        Write-Host "`n[SUCCESS] Target encontrado!" -ForegroundColor Green
        Write-Host "   Job: $($target.labels.job)" -ForegroundColor White
        Write-Host "   Health: $($target.health)" -ForegroundColor White
        Write-Host "   URL: $($target.scrapeUrl)" -ForegroundColor White
        Write-Host "   Last Scrape: $($target.lastScrape)" -ForegroundColor White
        Write-Host "   Scrape Duration: $($target.lastScrapeDuration)" -ForegroundColor White
    }
    else {
        Write-Host "`n[ERROR] Target NO encontrado en Prometheus" -ForegroundColor Red
        Write-Host "Esperando scraping... intente nuevamente en 30 segundos" -ForegroundColor Yellow
        exit 1
    }
}
catch {
    Write-Host "`n[ERROR] Error consultando Prometheus:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Verificar métrica up
Write-Host "`n[INFO] Verificando métrica 'up'..." -ForegroundColor Cyan

try {
    $upQuery = Invoke-RestMethod -Uri "$PrometheusUrl/api/v1/query?query=up{job=\"$JobName\"}" -Method Get
    
    if ($upQuery.data.result.Count -gt 0) {
        $value = $upQuery.data.result[0].value[1]
        if ($value -eq "1") {
            Write-Host "[SUCCESS] up{job=\"$JobName\"} = 1 (Target funcionando)" -ForegroundColor Green
        }
        else {
            Write-Host "[WARNING] up{job=\"$JobName\"} = $value (Target DOWN)" -ForegroundColor Red
        }
    }
    else {
        Write-Host "[WARNING] No se encontró la métrica up para el job" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "[ERROR] Error en consulta up:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}