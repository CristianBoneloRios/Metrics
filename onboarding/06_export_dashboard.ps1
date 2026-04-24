# 06_export_dashboard.ps1 - Exportar dashboard existente de Grafana
# Útil para respaldar o migrar dashboards

param(
    [string]$GrafanaUrl = "http://10.164.10.137:3000",
    [string]$GrafanaUser = "admin",
    [string]$GrafanaPassword = "admin",
    [string]$DashboardUid = "cristian-bonelo-servicio-codsp",
    [string]$OutputFile = (Join-Path (Split-Path $PSScriptRoot -Parent) "dashboard\exported_dashboard.json")
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Exportando Dashboard desde Grafana QAS" -ForegroundColor Yellow
Write-Host "Cristian Bonelo - onboarding-qas" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

$basicAuth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${GrafanaUser}:${GrafanaPassword}"))
$headers = @{
    "Authorization" = "Basic $basicAuth"
    "Content-Type" = "application/json"
}

try {
    $dashboard = Invoke-RestMethod -Uri "$GrafanaUrl/api/dashboards/uid/$DashboardUid" -Headers $headers -Method Get
    
    # Crear objeto para exportación
    $export = @{
        dashboard = $dashboard.dashboard
        overwrite = $true
        message = "Exportado por Cristian Bonelo - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        version = $dashboard.dashboard.version
    }
    
    $export | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputFile -Encoding UTF8
    
    Write-Host "[SUCCESS] Dashboard exportado exitosamente" -ForegroundColor Green
    Write-Host "   Archivo: $OutputFile" -ForegroundColor Cyan
    Write-Host "   Título: $($dashboard.dashboard.title)" -ForegroundColor Cyan
    Write-Host "   UID: $($dashboard.dashboard.uid)" -ForegroundColor Cyan
}
catch {
    Write-Host "[ERROR] Error exportando dashboard: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}