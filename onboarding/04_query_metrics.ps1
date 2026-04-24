# 04_query_metrics.ps1 - Consultas PromQL reales
param(
    [string]$PrometheusUrl = "http://10.164.10.137:9090",
    [string]$JobName = "servicio-codsp-integracion"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Consultas PromQL - CODSP QAS" -ForegroundColor Yellow
Write-Host "Cristian Bonelo - onboarding-qas" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

$queries = @(
    @{
        Name = "Estado del target"
        Query = "up{job=`"$JobName`"}"
    },
    @{
        Name = "Tasa de requests HTTP (últimos 5m)"
        Query = "sum(rate(http_requests_total{job=`"$JobName`"}[5m]))"
    },
    @{
        Name = "Tasa de errores HTTP (últimos 5m)"
        Query = "sum(rate(http_requests_total{job=`"$JobName`",status=~`"5..`"}[5m])) / clamp_min(sum(rate(http_requests_total{job=`"$JobName`"}[5m])), 1e-9) * 100"
    },
    @{
        Name = "Operaciones de negocio totales"
        Query = "codsp_operations_total"
    },
    @{
        Name = "Tasa de operaciones exitosas"
        Query = "rate(codsp_operations_total{status=`"success`",owner=`"cristian_bonelo`"}[5m])"
    },
    @{
        Name = "Documentos procesados por tipo"
        Query = "codsp_documents_processed_total"
    },
    @{
        Name = "Llamadas a APIs externas"
        Query = "codsp_external_api_calls_total"
    }
)

$results = @()

foreach ($q in $queries) {
    Write-Host "`n[QUERY] $($q.Name):" -ForegroundColor Cyan
    Write-Host "   Query: $($q.Query)" -ForegroundColor DarkGray
    
    try {
        $response = Invoke-RestMethod -Uri "$PrometheusUrl/api/v1/query?query=$([System.Web.HttpUtility]::UrlEncode($q.Query))" -Method Get
        
        if ($response.data.result.Count -gt 0) {
            Write-Host "   [SUCCESS] Resultado:" -ForegroundColor Green
            foreach ($result in $response.data.result) {
                if ($result.metric -and ($result.metric.PSObject.Properties.Count -gt 0)) {
                    $labels = ($result.metric.PSObject.Properties | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join ", "
                    Write-Host "      {$labels} → $($result.value[1])" -ForegroundColor White
                }
                else {
                    Write-Host "      Valor: $($result.value[1])" -ForegroundColor White
                }
            }
            $results += [PSCustomObject]@{Query = $q.Name; Status = "OK"; Value = $response.data.result[0].value[1]}
        }
        else {
            Write-Host "   [WARNING] Sin datos (puede necesitar generar tráfico)" -ForegroundColor Yellow
            $results += [PSCustomObject]@{Query = $q.Name; Status = "NO_DATA"; Value = $null}
        }
    }
    catch {
        Write-Host "   [ERROR] Error: $($_.Exception.Message)" -ForegroundColor Red
        $results += [PSCustomObject]@{Query = $q.Name; Status = "ERROR"; Value = $null}
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "RESUMEN DE VERIFICACIÓN" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

$results | Format-Table -AutoSize

# Guardar resultados
$projectRoot = Split-Path $PSScriptRoot -Parent
$metricsFile = Join-Path $projectRoot "metrics_results.csv"
$results | Export-Csv -Path $metricsFile -NoTypeInformation
Write-Host "[INFO] Resultados guardados en: $metricsFile" -ForegroundColor Cyan