@echo off
echo ========================================
echo Generando trafico real para CODSP
echo Cristian Bonelo - onboarding-qas
echo ========================================
echo.

set BASE_URL=http://localhost:8080

echo [1/5] Probando health...
curl -s %BASE_URL%/health
echo.

echo [2/5] Procesando documentos...
for /l %%i in (1,1,20) do (
    curl -s -X POST "%BASE_URL%/documents/process?document_name=doc%%i.txt&doc_type=pdf&size_bytes=50000" > nul
    echo    Documento %%i procesado
)

echo [3/5] Llamando APIs externas...
curl -s "%BASE_URL%/external/call/storage/upload" > nul
curl -s "%BASE_URL%/external/call/database/query" > nul
curl -s "%BASE_URL%/external/call/cache/get" > nul

echo [4/5] Ejecutando batch operations...
curl -s -X POST "%BASE_URL%/batch/operations?count=30" > nul

echo [5/5] Verificando metricas...
echo.
echo Ultimas metricas Prometheus:
curl -s "%BASE_URL%/metrics" | findstr "codsp_operations_total"

echo.
echo ========================================
echo Trafico generado exitosamente!
echo Verificar en Prometheus: http://10.164.10.137:9090
echo ========================================
pause