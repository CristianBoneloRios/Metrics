# 02_register_service.ps1 - Registrar servicio en catálogo CODSP
param(
    [string]$CodspUrl = "http://10.164.10.137:8000",
    [string]$TokenFile = (Join-Path $PSScriptRoot "token.txt"),
    [string]$ServiceName = "servicio-codsp-integracion",
    [string]$DisplayName = "Servicio CODSP Integracion",
    [string]$TargetHost = "",
    [int]$TargetPort = 8080
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CODSP QAS - Registrando Servicio" -ForegroundColor Yellow
Write-Host "Cristian Bonelo - onboarding-qas" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

# Leer token
if (-not (Test-Path $TokenFile)) {
    Write-Host "[ERROR] Token no encontrado. Ejecute primero 01_get_token.ps1" -ForegroundColor Red
    exit 1
}

$token = Get-Content $TokenFile -Raw

if (-not $TargetHost) {
    # Fallback para no bloquear ejecución: detecta una IPv4 local.
    # Recomendado: pasar -TargetHost explícitamente con el DNS/IP visible desde Prometheus.
    $TargetHost = (Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object { $_.InterfaceAlias -notlike "*Loopback*" } |
        Select-Object -First 1).IPAddress
}

if (-not $TargetHost) {
    Write-Host "[ERROR] No se pudo determinar TargetHost. Use -TargetHost manualmente." -ForegroundColor Red
    exit 1
}

Write-Host "[INFO] Target configurado: ${TargetHost}:${TargetPort}" -ForegroundColor Cyan

$payload = @{
    name = $ServiceName
    display_name = $DisplayName
    team = "observabilidad"
    project = "onboarding-qas"
    environment = "qas"
    targets = @("${TargetHost}:${TargetPort}")
    metrics_path = "/metrics"
    scheme = "http"
    extra_labels = @{
        owner = "Cristian Bonelo"
        language = "python"
        framework = "fastapi"
        team = "observabilidad"
        project = "onboarding-qas"
        environment = "qas"
        onboarded_by = "Cristian Bonelo"
        date = (Get-Date -Format "yyyy-MM-dd")
    }
} | ConvertTo-Json -Depth 10

Write-Host "`n[INFO] Payload de registro:" -ForegroundColor Cyan
Write-Host $payload -ForegroundColor White

try {
    $response = Invoke-RestMethod -Uri "$CodspUrl/api/v1/catalog/services" `
        -Method Post `
        -Headers @{
            "Authorization" = "Bearer $token"
            "Content-Type" = "application/json"
        } `
        -Body $payload
    
    Write-Host "`n[SUCCESS] Servicio registrado exitosamente!" -ForegroundColor Green
    Write-Host "Respuesta:" -ForegroundColor White
    $response | ConvertTo-Json -Depth 5
}
catch {
    Write-Host "`n[ERROR] Error al registrar servicio:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd()
        Write-Host "Detalle: $responseBody" -ForegroundColor Red
    }
    exit 1
}