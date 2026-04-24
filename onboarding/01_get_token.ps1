# 01_get_token.ps1 - Obtener token JWT del CODSP en QAS
param(
    [string]$Username = "admin.user",
    [string]$Password = "admin123",
    [string]$CodspUrl = "http://10.164.10.137:8000"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CODSP QAS - Obteniendo Token" -ForegroundColor Yellow
Write-Host "Cristian Bonelo - onboarding-qas" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

$loginBody = @{
    username = $Username
    password = $Password
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$CodspUrl/api/v1/auth/login" `
        -Method Post `
        -ContentType "application/json" `
        -Body $loginBody
    
    $token = $response.access_token
    
    Write-Host "`n[SUCCESS] Token obtenido exitosamente!" -ForegroundColor Green
    Write-Host "Token: $token" -ForegroundColor White
    
    # Guardar token en la misma carpeta de onboarding para otros scripts
    $tokenFile = Join-Path $PSScriptRoot "token.txt"
    $token | Out-File -FilePath $tokenFile -NoNewline
    
    Write-Host "`n[INFO] Token guardado en: $tokenFile" -ForegroundColor Cyan
    
    return $token
}
catch {
    Write-Host "`n[ERROR] Error al obtener token:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}