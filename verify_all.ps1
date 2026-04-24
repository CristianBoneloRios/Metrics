# verify_all.ps1 - Verificación end-to-end completa
Write-Host @"
╔══════════════════════════════════════════════════════════════╗
║     CODSP ONBOARDING - VERIFICACIÓN COMPLETA                ║
║     Cristian Bonelo - onboarding-qas                        ║
║     Team: observabilidad                                    ║
╚══════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan
# Este script realiza una verificación completa del servicio integrado con CODSP QAS, incluyendo:
# 1. Verificar que el servicio local esté corriendo y respondiendo en localhost:8080
# 2. Verificar que el endpoint /metrics esté disponible y contenga métricas de Prometheus
# 3. Verificar que se pueda autenticar con CODSP QAS y obtener un token válido
# 4. Verificar que Prometheus QAS esté accesible
$errores = 0
$verificaciones = @()

# 1. Verificar servicio local
Write-Host "`n[1/6] Verificando servicio local..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "http://localhost:8080/health" -TimeoutSec 5
    if ($health.status -eq "healthy") {
        Write-Host "  [SUCCESS] Servicio local OK - Cristian Bonelo" -ForegroundColor Green
        $verificaciones += "Servicio local: OK"
    }
} catch {
    Write-Host "  [ERROR] Servicio local NO RESPONDE" -ForegroundColor Red
    $runBat = Join-Path $PSScriptRoot "service\run.bat"
    Write-Host "     Ejecute: $runBat" -ForegroundColor Yellow
    $errores++
}

# 2. Verificar métricas locales
Write-Host "`n[2/6] Verificando endpoint /metrics..." -ForegroundColor Yellow
try {
    $metrics = Invoke-WebRequest -Uri "http://localhost:8080/metrics" -TimeoutSec 5
    if ($metrics.Content -match "codsp_operations_total") {
        Write-Host "  [SUCCESS] Métricas Prometheus encontradas" -ForegroundColor Green
        $verificaciones += "Métricas: OK"
    }
} catch {
    Write-Host "  [ERROR] Error en /metrics" -ForegroundColor Red
    $errores++
}

# 3. Verificar token CODSP
Write-Host "`n[3/6] Verificando autenticación CODSP QAS..." -ForegroundColor Yellow
try {
    $login = Invoke-RestMethod -Uri "http://10.164.10.137:8000/api/v1/auth/login" `
        -Method Post `
        -ContentType "application/json" `
        -Body '{"username":"admin.user","password":"admin123"}'
    
    if ($login.access_token) {
        Write-Host "  [SUCCESS] Autenticación CODSP exitosa" -ForegroundColor Green
        $tokenValidatedPath = Join-Path $PSScriptRoot "token_validated.txt"
        $login.access_token | Out-File -FilePath $tokenValidatedPath
        $verificaciones += "CODSP Auth: OK"
    }
} catch {
    Write-Host "  [ERROR] No se pudo autenticar con CODSP" -ForegroundColor Red
    Write-Host "     Verifique conexión a 10.164.10.137" -ForegroundColor Yellow
    $errores++
}

# 4. Verificar Prometheus
Write-Host "`n[4/6] Verificando Prometheus QAS..." -ForegroundColor Yellow
try {
    $promStatus = Invoke-RestMethod -Uri "http://10.164.10.137:9090/api/v1/query?query=up" -TimeoutSec 5
    if ($promStatus.status -eq "success") {
        Write-Host "  [SUCCESS] Prometheus accesible" -ForegroundColor Green
        $verificaciones += "Prometheus: OK"
    }
} catch {
    Write-Host "  [ERROR] Prometheus no responde" -ForegroundColor Red
    $errores++
}

# 5. Generar tráfico de prueba
Write-Host "`n[5/6] Generando tráfico de prueba..." -ForegroundColor Yellow
try {
    for ($i = 1; $i -le 10; $i++) {
        Invoke-RestMethod -Uri "http://localhost:8080/documents/process?document_name=verify_$i.txt&doc_type=test&size_bytes=5000" -Method Post | Out-Null
    }
    Write-Host "  [SUCCESS] 10 documentos procesados" -ForegroundColor Green
    $verificaciones += "Tráfico generado: 10 documentos"
} catch {
    Write-Host "  [WARNING] Error generando tráfico" -ForegroundColor Yellow
}

# 6. Resumen final
Write-Host "`n[6/6] RESUMEN FINAL" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
foreach ($v in $verificaciones) {
    Write-Host "  $v" -ForegroundColor White
}

if ($errores -eq 0) {
    Write-Host "`n[SUCCESS] VERIFICACIÓN COMPLETA - TODO OK" -ForegroundColor Green
    Write-Host "   Servicio integrado correctamente con CODSP QAS" -ForegroundColor Green
    Write-Host "   Owner: Cristian Bonelo" -ForegroundColor Cyan
    Write-Host "   Team: observabilidad" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   Grafana: http://10.164.10.137:3000" -ForegroundColor White
    Write-Host "   Importar dashboard: dashboard/grafana_dashboard_cristian_bonelo.json" -ForegroundColor White
} else {
    Write-Host "`n[WARNING] Se encontraron $errores problemas" -ForegroundColor Yellow
    Write-Host "   Revise que el servicio esté corriendo: run.bat" -ForegroundColor Yellow
}

exit $errores