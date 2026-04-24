# 05_create_dashboard.ps1 - Crear dashboard en Grafana vía API
# Cristian Bonelo - onboarding-qas - CODSP QAS

param(
    [string]$GrafanaUrl = "http://10.164.10.137:3000",
    [string]$GrafanaUser = "admin",
    [string]$GrafanaPassword = "admin",
    [string]$DashboardFile = (Join-Path (Split-Path $PSScriptRoot -Parent) "dashboard\grafana_dashboard_cristian_bonelo.json"),
    [string]$PrometheusDatasource = "Prometheus"
)

Write-Host @"
╔══════════════════════════════════════════════════════════════╗
║     GRAFANA DASHBOARD CREATION - CODSP QAS                   ║
║     Cristian Bonelo - onboarding-qas                        ║
║     Team: observabilidad                                    ║
╚══════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

# Variables de error
$global:errorCount = 0

# ============================================================
# 1. Verificar que el archivo del dashboard existe
# ============================================================
Write-Host "`n[1/7] Verificando archivo dashboard..." -ForegroundColor Yellow

if (-not (Test-Path $DashboardFile)) {
    Write-Host "[ERROR] No se encuentra el archivo: $DashboardFile" -ForegroundColor Red
    Write-Host "   Asegúrese de que el archivo existe en la ruta correcta" -ForegroundColor Red
    exit 1
}

Write-Host "[SUCCESS] Dashboard file encontrado: $DashboardFile" -ForegroundColor Green

# ============================================================
# 2. Obtener token de autenticación de Grafana
# ============================================================
Write-Host "`n[2/7] Autenticando en Grafana..." -ForegroundColor Yellow

try {
    # Grafana usa Basic Auth o API Keys. Vamos a usar Basic Auth
    $basicAuth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${GrafanaUser}:${GrafanaPassword}"))
    
    $authHeaders = @{
        "Authorization" = "Basic $basicAuth"
        "Content-Type" = "application/json"
    }
    
    # Verificar conexión a Grafana
    $healthCheck = Invoke-RestMethod -Uri "$GrafanaUrl/api/health" -Headers $authHeaders -Method Get -TimeoutSec 5
    
    if ($healthCheck.database -eq "ok") {
        Write-Host "[SUCCESS] Conexión a Grafana exitosa" -ForegroundColor Green
        Write-Host "   Versión: $($healthCheck.version)" -ForegroundColor Cyan
    }
    else {
        throw "Grafana health check falló"
    }
}
catch {
    Write-Host "[ERROR] No se pudo conectar a Grafana en $GrafanaUrl" -ForegroundColor Red
    Write-Host "   Detalle: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "   Posibles soluciones:" -ForegroundColor Yellow
    Write-Host "   1. Verifique que Grafana está corriendo en 10.164.10.137:3000" -ForegroundColor White
    Write-Host "   2. Verifique credenciales (admin/admin por defecto)" -ForegroundColor White
    Write-Host "   3. Si cambió la contraseña, ejecute con parámetros:" -ForegroundColor White
    Write-Host "      .\05_create_dashboard.ps1 -GrafanaPassword 'su_contraseña'" -ForegroundColor White
    exit 1
}

# ============================================================
# 3. Obtener UID del datasource Prometheus
# ============================================================
Write-Host "`n[3/7] Buscando datasource Prometheus..." -ForegroundColor Yellow

try {
    $datasources = Invoke-RestMethod -Uri "$GrafanaUrl/api/datasources" -Headers $authHeaders -Method Get
    
    $prometheusDs = $datasources | Where-Object { $_.type -eq "prometheus" -or $_.name -eq $PrometheusDatasource }
    
    if ($prometheusDs) {
        $datasourceUid = $prometheusDs.uid
        Write-Host "[SUCCESS] Datasource Prometheus encontrado" -ForegroundColor Green
        Write-Host "   Nombre: $($prometheusDs.name)" -ForegroundColor Cyan
        Write-Host "   UID: $datasourceUid" -ForegroundColor Cyan
        Write-Host "   URL: $($prometheusDs.url)" -ForegroundColor Cyan
    }
    else {
        Write-Host "[WARNING] No se encontró datasource Prometheus automáticamente" -ForegroundColor Yellow
        Write-Host "   Se usará el UID por defecto: 'prometheus'" -ForegroundColor Yellow
        $datasourceUid = "prometheus"
    }
}
catch {
    Write-Host "[WARNING] Error obteniendo datasources: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "   Se usará UID por defecto: 'prometheus'" -ForegroundColor Yellow
    $datasourceUid = "prometheus"
}

# ============================================================
# 4. Leer y preparar el dashboard JSON
# ============================================================
Write-Host "`n[4/7] Preparando dashboard JSON..." -ForegroundColor Yellow

try {
    # Leer el dashboard
    $dashboardJson = Get-Content -Path $DashboardFile -Raw -Encoding UTF8 | ConvertFrom-Json
    
    # Extraer el dashboard object (puede venir envuelto en "dashboard" o directamente)
    if ($dashboardJson.dashboard) {
        $dashboard = $dashboardJson.dashboard
    }
    else {
        $dashboard = $dashboardJson
    }
    
    # Asegurar que el dashboard tenga el datasource UID correcto
    # Recorrer todos los paneles y reemplazar datasource
    if ($dashboard.panels) {
        foreach ($panel in $dashboard.panels) {
            if ($panel.targets) {
                foreach ($target in $panel.targets) {
                    if ($target.datasource -or $target.datasourceUid) {
                        $target.datasourceUid = $datasourceUid
                    }
                }
            }
        }
    }
    
    # Construir payload para la API de Grafana
    $payload = @{
        dashboard = $dashboard
        overwrite = $true
        message = "Dashboard creado por Cristian Bonelo - onboarding CODSP QAS"
    } | ConvertTo-Json -Depth 10
    
    Write-Host "[SUCCESS] Dashboard JSON preparado" -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] ERROR al leer el archivo JSON: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# ============================================================
# 5. Verificar si el dashboard ya existe
# ============================================================
Write-Host "`n[5/7] Verificando si dashboard ya existe..." -ForegroundColor Yellow

$dashboardUid = $dashboard.uid
$dashboardExists = $false

if ($dashboardUid) {
    try {
        $existingDashboard = Invoke-RestMethod -Uri "$GrafanaUrl/api/dashboards/uid/$dashboardUid" -Headers $authHeaders -Method Get -ErrorAction SilentlyContinue
        if ($existingDashboard.dashboard) {
            $dashboardExists = $true
            Write-Host "[WARNING] Dashboard ya existe con UID: $dashboardUid" -ForegroundColor Yellow
            Write-Host "   Se sobrescribirá (overwrite=true)" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "[SUCCESS] Dashboard no existe, se creará uno nuevo" -ForegroundColor Green
    }
}

# ============================================================
# 6. Crear/Actualizar dashboard en Grafana
# ============================================================
Write-Host "`n[6/7] $('Actualizando' if $dashboardExists else 'Creando') dashboard en Grafana..." -ForegroundColor Yellow

try {
    $result = Invoke-RestMethod -Uri "$GrafanaUrl/api/dashboards/db" `
        -Headers $authHeaders `
        -Method Post `
        -Body $payload `
        -ContentType "application/json"
    
    Write-Host "[SUCCESS] Dashboard $('actualizado' if $dashboardExists else 'creado') exitosamente!" -ForegroundColor Green
    Write-Host ""
    Write-Host "   [INFO] URL del Dashboard: $GrafanaUrl$($result.url)" -ForegroundColor Cyan
    Write-Host "   [INFO] UID: $($result.uid)" -ForegroundColor Cyan
    Write-Host "   [INFO] Versión: $($result.version)" -ForegroundColor Cyan
    Write-Host "   [INFO] Owner: Cristian Bonelo" -ForegroundColor Cyan
}
catch {
    Write-Host "[ERROR] ERROR al crear/actualizar dashboard:" -ForegroundColor Red
    Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd()
        Write-Host "   Detalle: $responseBody" -ForegroundColor Red
    }
    $global:errorCount++
}

# ============================================================
# 7. Verificar que el dashboard está accesible
# ============================================================
Write-Host "`n[7/7] Verificando dashboard creado..." -ForegroundColor Yellow

if ($result -and $result.uid) {
    try {
        $verifyDashboard = Invoke-RestMethod -Uri "$GrafanaUrl/api/dashboards/uid/$($result.uid)" -Headers $authHeaders -Method Get
        Write-Host "[SUCCESS] Dashboard verificado y accesible" -ForegroundColor Green
        Write-Host "   Título: $($verifyDashboard.dashboard.title)" -ForegroundColor Cyan
        Write-Host "   Paneles: $($verifyDashboard.dashboard.panels.Count)" -ForegroundColor Cyan
    }
    catch {
        Write-Host "[WARNING] No se pudo verificar el dashboard, pero la creación fue exitosa" -ForegroundColor Yellow
    }
}

# ============================================================
# RESUMEN FINAL
# ============================================================
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    RESUMEN DE CREACIÓN                       ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "[INFO] Dashboard: Servicio CODSP - Cristian Bonelo" -ForegroundColor White
Write-Host "[INFO] Owner: Cristian Bonelo" -ForegroundColor White
Write-Host "[INFO] Team: observabilidad" -ForegroundColor White
Write-Host "[INFO] Project: onboarding-qas" -ForegroundColor White
Write-Host "[INFO] Entorno: QAS" -ForegroundColor White
Write-Host ""

if ($result -and $result.uid -and $global:errorCount -eq 0) {
    Write-Host "[SUCCESS] DASHBOARD CREADO CON ÉXITO" -ForegroundColor Green
    Write-Host ""
    Write-Host "[INFO] URL para acceder:" -ForegroundColor Yellow
    Write-Host "   $GrafanaUrl$($result.url)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "[INFO] Para ver las métricas de negocio:" -ForegroundColor Yellow
    Write-Host "   1. Genere tráfico con: ..\service\test_traffic.bat" -ForegroundColor White
    Write-Host "   2. Espere 30 segundos" -ForegroundColor White
    Write-Host "   3. Refresh en Grafana" -ForegroundColor White
}
else {
    Write-Host "[WARNING] HUBO PROBLEMAS DURANTE LA CREACIÓN" -ForegroundColor Yellow
    Write-Host "   Revise los errores arriba e intente nuevamente" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Script completado - Cristian Bonelo" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan

# Guardar información del dashboard para referencia
$dashboardInfo = @{
    created_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    owner = "Cristian Bonelo"
    team = "observabilidad"
    project = "onboarding-qas"
    environment = "qas"
    grafana_url = $GrafanaUrl
    dashboard_url = if ($result) { "$GrafanaUrl$($result.url)" } else { "No creado" }
    dashboard_uid = if ($result) { $result.uid } else { "No creado" }
    status = if ($global:errorCount -eq 0) { "SUCCESS" } else { "PARTIAL_FAILURE" }
} | ConvertTo-Json

$projectRoot = Split-Path $PSScriptRoot -Parent
$dashboardInfoFile = Join-Path $projectRoot "dashboard_creation_info.json"
$dashboardInfo | Out-File -FilePath $dashboardInfoFile -Encoding UTF8
Write-Host "Informacion guardada en: $dashboardInfoFile" -ForegroundColor Cyan

exit $global:errorCount