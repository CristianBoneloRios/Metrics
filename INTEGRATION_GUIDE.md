# GuÃ­a de IntegraciÃ³n con CODSP QAS

## IntroducciÃ³n

Esta guÃ­a proporciona instrucciones detalladas para integrar un nuevo servicio con **CODSP QAS**, la plataforma centralizada de observabilidad. Utilizaremos como referencia la implementaciÃ³n del servicio CODSP IntegraciÃ³n - Cristian Bonelo.

**Objetivo**: Lograr que tu servicio sea completamente observable con mÃ©tricas de negocio, alertas y dashboards en Grafana.

---

## Requisitos Previos

### Entorno TÃ©cnico

- **Lenguaje**: Python 3.9+
- **Framework Web**: FastAPI (recomendado) o similar
- **LibrerÃ­a de MÃ©tricas**: prometheus-client
- **Instrumentador HTTP**: prometheus-fastapi-instrumentator

### Acceso a Infraestructura

```
CODSP QAS:      http://10.164.10.137:8000
Prometheus:     http://10.164.10.137:9090
Grafana:        http://10.164.10.137:3000
Username:       admin.user
Password:       admin123
```

### Herramientas Necesarias

- Python 3.9+
- pip (gestor de paquetes)
- PowerShell 5.1+ (para scripts de onboarding)
- curl o similar (para testing)
- Git (opcional, para versionado)

---

## Estructura de Archivos Recomendada

```
tu-servicio/
â”œâ”€â”€ main.py                  # AplicaciÃ³n principal
â”œâ”€â”€ business.py              # LÃ³gica de negocio
â”œâ”€â”€ metrics.py               # Definiciones de mÃ©tricas
â”œâ”€â”€ requirements.txt         # Dependencias Python
â”œâ”€â”€ run.bat                  # Script para ejecutar (Windows/CMD)
â”œâ”€â”€ run.ps1                  # Script para ejecutar (Windows/PowerShell)
â”œâ”€â”€ test_traffic.bat         # Generador de trÃ¡fico de prueba
â”‚
â”œâ”€â”€ onboarding/              # Scripts de integraciÃ³n con CODSP
â”‚   â”œâ”€â”€ 01_get_token.ps1
â”‚   â”œâ”€â”€ 02_register_service.ps1
â”‚   â”œâ”€â”€ 03_verify_prometheus.ps1
â”‚   â”œâ”€â”€ 04_query_metrics.ps1
â”‚   â”œâ”€â”€ 05_create_dashboard.ps1
â”‚   â””â”€â”€ 06_export_dashboard.ps1
â”‚
â”œâ”€â”€ dashboard/               # ConfiguraciÃ³n de Grafana
â”‚   â””â”€â”€ grafana_dashboard.json
â”‚
â”œâ”€â”€ README.md                # DocumentaciÃ³n principal
â”œâ”€â”€ INTEGRATION_GUIDE.md      # Esta guÃ­a
â”œâ”€â”€ verify_all.ps1           # VerificaciÃ³n completa
â””â”€â”€ requirements.txt         # Dependencias
```

---

## Paso 1: Preparar el Proyecto Python

### 1.1 InstalaciÃ³n de Dependencias

Crea un archivo `requirements.txt` con las librerÃ­as necesarias:

```
fastapi==0.104.1
uvicorn==0.24.0
prometheus-client==0.19.0
prometheus-fastapi-instrumentator==6.1.0
httpx==0.25.1
```

Instala las dependencias:

```bash
pip install -r requirements.txt
```

### 1.2 Estructura Basic de main.py

```python
from contextlib import asynccontextmanager
from fastapi import FastAPI
from prometheus_fastapi_instrumentator import Instrumentator
import uvicorn

from metrics import register_custom_metrics
from business import your_business_functions

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Inicializar mÃ©tricas al startup"""
    register_custom_metrics()
    print("[SUCCESS] Servicio iniciado")
    yield
    print("[INFO] Servicio detenido")

app = FastAPI(
    title="Tu Servicio",
    description="DescripciÃ³n del servicio",
    version="1.0.0",
    lifespan=lifespan
)

# Endpoint de health
@app.get("/health")
async def health():
    return {"status": "healthy"}

# Instrumentador Prometheus
instrumentator = Instrumentator(
    should_group_status_codes=True,
    should_ignore_untemplated=True,
)
instrumentator.instrument(app)
instrumentator.expose(app, endpoint="/metrics", include_in_schema=False)

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8080, reload=False)
```

---

## Paso 2: Definir MÃ©tricas de Negocio

### 2.1 Crear metrics.py

Defines todas tus mÃ©tricas en un archivo centralizado:

```python
from prometheus_client import Counter, Histogram, Gauge, Info

# Identidad del servicio
SERVICE_INFO = Info("service_info", "InformaciÃ³n del servicio")
SERVICE_INFO.info({
    "owner": "Tu Nombre",
    "team": "tu-equipo",
    "project": "nombre-proyecto",
    "environment": "qas"
})

# Ejemplo: MÃ©trica de operaciones
OPERATIONS_TOTAL = Counter(
    "operations_total",
    "Total de operaciones",
    labelnames=["operation_type", "status", "owner"]
)

# Ejemplo: MÃ©trica de duraciÃ³n
OPERATION_DURATION = Histogram(
    "operation_duration_seconds",
    "DuraciÃ³n en segundos",
    labelnames=["operation_type"],
    buckets=(0.01, 0.05, 0.1, 0.5, 1.0, 5.0, 10.0)
)

def register_custom_metrics():
    """Hook para registrar mÃ©tricas"""
    pass
```

### 2.2 Tipos de MÃ©tricas

**Counter** - Incrementa siempre:
```python
OPERATIONS_TOTAL.labels(operation_type="process", status="success").inc()
```

**Histogram** - Mide distribuciones:
```python
duration = time.time() - start_time
OP_DURATION.labels(operation_type="process").observe(duration)
```

**Gauge** - Sube y baja:
```python
ACTIVE_TASKS.inc()    # Sube
ACTIVE_TASKS.dec()    # Baja
```

**Info** - Metadatos del servicio:
```python
SERVICE_INFO.info({"key": "value"})
```

---

## Paso 3: Implementar LÃ³gica de Negocio

### 3.1 Crear business.py

```python
import time
from metrics import OPERATIONS_TOTAL, OPERATION_DURATION

def process_operation(operation_name: str, data: dict) -> dict:
    """Procesa una operaciÃ³n real"""
    start_time = time.time()
    status = "error"
    
    try:
        # Tu lÃ³gica aquÃ­
        result = do_something_with(data)
        status = "success"
        
        return {"status": "ok", "result": result}
        
    except Exception as e:
        return {"status": "error", "error": str(e)}
        
    finally:
        # Registrar mÃ©tricas
        OPERATIONS_TOTAL.labels(
            operation_type=operation_name,
            status=status,
            owner="tu-nombre"
        ).inc()
        
        OPERATION_DURATION.labels(
            operation_type=operation_name
        ).observe(time.time() - start_time)
```

### 3.2 Integrar en main.py

```python
from business import process_operation

@app.post("/api/operation")
async def api_operation(operation_type: str, data: dict):
    result = process_operation(operation_type, data)
    if result["status"] == "error":
        raise HTTPException(status_code=500, detail=result["error"])
    return result
```

---

## Paso 4: Scripts de Onboarding

### 4.1 01_get_token.ps1

```powershell
# Obtener token JWT de CODSP
param(
    [string]$CodspUrl = "http://10.164.10.137:8000",
    [string]$Username = "admin.user",
    [string]$Password = "admin123"
)

$loginBody = @{
    username = $Username
    password = $Password
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$CodspUrl/api/v1/auth/login" `
        -Method Post -ContentType "application/json" -Body $loginBody
    
    Write-Host "[SUCCESS] Token obtenido" -ForegroundColor Green
    $response.access_token | Out-File "token.txt" -NoNewline
    
} catch {
    Write-Host "[ERROR] Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
```

### 4.2 02_register_service.ps1

Registra tu servicio en el catÃ¡logo CODSP:

```powershell
param(
    [string]$ServiceName = "mi-servicio",
    [string]$LocalIp = "localhost",
    [int]$Port = 8080
)

$token = Get-Content "token.txt" -Raw

$payload = @{
    name = $ServiceName
    targets = @("${LocalIp}:${Port}")
    metrics_path = "/metrics"
    extra_labels = @{
        owner = "Tu Nombre"
        team = "tu-equipo"
        environment = "qas"
    }
} | ConvertTo-Json -Depth 10

Invoke-RestMethod -Uri "http://10.164.10.137:8000/api/v1/catalog/services" `
    -Method Post `
    -Headers @{"Authorization" = "Bearer $token"} `
    -Body $payload -ContentType "application/json"
```

---

## Paso 5: Scripts de VerificaciÃ³n

### 5.1 03_verify_prometheus.ps1

```powershell
param([string]$JobName = "mi-servicio")

$response = Invoke-RestMethod -Uri "http://10.164.10.137:9090/api/v1/targets?state=active"

$target = $response.data.activeTargets | Where-Object { $_.labels.job -eq $JobName }

if ($target) {
    Write-Host "[SUCCESS] Target encontrado" -ForegroundColor Green
    Write-Host "   Job: $($target.labels.job)" -ForegroundColor Cyan
    Write-Host "   Health: $($target.health)" -ForegroundColor Cyan
} else {
    Write-Host "[ERROR] Target no encontrado" -ForegroundColor Red
}
```

### 5.2 04_query_metrics.ps1

```powershell
$queries = @(
    @{ Name = "Estado"; Query = "up{job=`"mi-servicio`"}" },
    @{ Name = "Requests/s"; Query = "rate(http_requests_total[5m])" }
)

foreach ($q in $queries) {
    $result = Invoke-RestMethod -Uri "http://10.164.10.137:9090/api/v1/query?query=$([System.Web.HttpUtility]::UrlEncode($q.Query))"
    Write-Host "[QUERY] $($q.Name): $($result.data.result[0].value[1])" -ForegroundColor Cyan
}
```

---

## Paso 6: Dashboard en Grafana

### 6.1 Crear dashboard.json

Estructura bÃ¡sica de un dashboard Grafana:

```json
{
  "dashboard": {
    "title": "Mi Servicio",
    "uid": "mi-servicio",
    "tags": ["mi-equipo", "observabilidad"],
    "panels": [
      {
        "title": "Requests HTTP",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total[5m])",
            "legendFormat": "{{method}} {{path}}"
          }
        ]
      },
      {
        "title": "Operaciones",
        "type": "stat",
        "targets": [
          {
            "expr": "operations_total",
            "legendFormat": "{{operation_type}}"
          }
        ]
      }
    ]
  }
}
```

### 6.2 05_create_dashboard.ps1

```powershell
param(
    [string]$DashboardFile = "dashboard.json"
)

$basicAuth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("admin:admin"))

$dashboard = Get-Content $DashboardFile -Raw | ConvertFrom-Json

$payload = @{
    dashboard = $dashboard.dashboard
    overwrite = $true
} | ConvertTo-Json -Depth 10

Invoke-RestMethod -Uri "http://10.164.10.137:3000/api/dashboards/db" `
    -Method Post `
    -Headers @{"Authorization" = "Basic $basicAuth"} `
    -Body $payload -ContentType "application/json"
```

---

## Paso 7: Scripts de EjecuciÃ³n

### 7.1 run.ps1

```powershell
Write-Host "Iniciando servicio..." -ForegroundColor Green
Write-Host "Metrics: http://localhost:8080/metrics" -ForegroundColor White
Write-Host "Health: http://localhost:8080/health" -ForegroundColor White

pip install -r requirements.txt
python main.py
```

### 7.2 run.bat

```batch
@echo off
cd /d %~dp0
echo Instalando dependencias...
pip install -r requirements.txt
echo.
echo Iniciando servicio...
python main.py
pause
```

### 7.3 test_traffic.bat

Script para generar trÃ¡fico de prueba:

```batch
@echo off
set BASE_URL=http://localhost:8080

echo Generando trafico...
for /l %%i in (1,1,50) do (
    curl -s -X POST "%BASE_URL%/api/operation?type=test" > nul
    echo Operacion %%i completada
)

echo Trafico generado. Verificar en Prometheus.
```

---

## Mejores PrÃ¡cticas

### 1. Nomenclatura de MÃ©tricas

```
[prefijo]_[nombre]_[unidad]
```

Ejemplos:
- `myservice_requests_total`
- `myservice_processing_seconds`
- `myservice_errors_total`

### 2. Labels Consistentes

Siempre incluye labels importantes:
```python
.labels(
    operation_type="...",
    status="success|error",
    owner="tu-nombre"
)
```

### 3. Health Checks

Implementa tres endpoints:
```python
@app.get("/health")           # BÃ¡sico
@app.get("/health/live")      # Liveness - estÃ¡ vivo
@app.get("/health/ready")     # Readiness - listo para recibir trÃ¡fico
```

### 4. DocumentaciÃ³n

Cada mÃ©trica debe tener descripciÃ³n clara:
```python
Counter(
    "my_metric",
    "DescripciÃ³n clara de quÃ© mide esta mÃ©trica",
    labelnames=["label1", "label2"]
)
```

### 5. Error Handling

Siempre captura y registra errores:
```python
try:
    # operaciÃ³n
    status = "success"
except Exception as e:
    status = "error"
    logger.error(f"Error: {e}")
finally:
    METRIC.labels(status=status).inc()
```

---

## Flujo de IntegraciÃ³n Completo

```
1. Preparar cÃ³digo Python (main.py, business.py, metrics.py)
   â†“
2. Crear requirements.txt
   â†“
3. Ejecutar servicio localmente (run.ps1)
   â†“
4. Generar trÃ¡fico de prueba (test_traffic.bat)
   â†“
5. Ejecutar 01_get_token.ps1
   â†“
6. Ejecutar 02_register_service.ps1
   â†“
7. Esperar 30-60 segundos (scraping de Prometheus)
   â†“
8. Ejecutar 03_verify_prometheus.ps1
   â†“
9. Ejecutar 04_query_metrics.ps1
   â†“
10. Crear dashboard.json
    â†“
11. Ejecutar 05_create_dashboard.ps1
    â†“
12. Verificar en Grafana: http://10.164.10.137:3000
```

---

## Ejemplos PrÃ¡cticos

### Ejemplo 1: Servicio de Procesamiento de Documentos

```python
def process_document(doc_name: str, doc_type: str, size_bytes: int):
    """Procesa un documento con mÃ©tricas"""
    start_time = time.time()
    status = "error"
    
    try:
        # Validar
        if size_bytes > 100_000_000:
            raise ValueError("Documento muy grande")
        
        # Procesar
        result = simulate_processing(doc_name)
        status = "success"
        
        return {"status": "ok", "processed": result}
        
    except Exception as e:
        return {"status": "error", "error": str(e)}
        
    finally:
        # MÃ©tricas
        DOCUMENTS_PROCESSED.labels(
            doc_type=doc_type,
            status=status
        ).inc()
        
        DOC_PROCESSING_TIME.labels(
            doc_type=doc_type
        ).observe(time.time() - start_time)
        
        DOC_SIZE_BYTES.labels(
            doc_type=doc_type
        ).observe(size_bytes)
```

### Ejemplo 2: API Externa

```python
async def call_external_api(service: str, endpoint: str):
    """Llama API externa con mÃ©tricas"""
    start_time = time.time()
    status = "success"
    
    try:
        # Llamada
        response = await httpx.get(f"http://{service}/{endpoint}")
        
        if response.status_code >= 400:
            status = "error"
            
        return {"status": status, "data": response.json()}
        
    finally:
        EXTERNAL_API_CALLS.labels(
            service=service,
            endpoint=endpoint,
            status=status
        ).inc()
        
        API_LATENCY.labels(
            service=service
        ).observe(time.time() - start_time)
```

---

## Troubleshooting

### El servicio no se registra en CODSP

```
[ERROR] 401: Unauthorized

SoluciÃ³n:
1. Verificar token: type token.txt
2. Regenerar token: .\01_get_token.ps1
3. Verificar credenciales (admin.user / admin123)
```

### Prometheus no ve las mÃ©tricas

```
[ERROR] No data en Prometheus

SoluciÃ³n:
1. Generar trÃ¡fico: test_traffic.bat
2. Esperar 30 segundos
3. Verificar /metrics: curl http://localhost:8080/metrics
4. Ver logs de Prometheus: http://10.164.10.137:9090/targets
```

### Dashboard no muestra datos

```
[ERROR] Panels vacÃ­os en Grafana

SoluciÃ³n:
1. Verificar datasource Prometheus estÃ¡ configurado
2. Generar mÃ¡s trÃ¡fico
3. Verificar queries en Grafana (resolver variables)
4. Checar que las mÃ©tricas existen en Prometheus
```

### CORS o Headers incorrectos

```
[ERROR] Unauthorized en API calls

SoluciÃ³n:
1. Certificar headers Authorization: "Bearer {token}"
2. Content-Type: application/json
3. URL correcta sin trailing slash
```

---

## ValidaciÃ³n Final

Lista de comprobaciÃ³n de integraciÃ³n:

- [ ] Servicio ejecutÃ¡ndose en http://localhost:8080
- [ ] `/health` responde con status "healthy"
- [ ] `/metrics` contiene tus mÃ©tricas personalizadas
- [ ] Token obtenido correctamente (token.txt)
- [ ] Servicio registrado en CODSP
- [ ] Target visible en Prometheus
- [ ] MÃ©tricas aparecer en queries PromQL
- [ ] Dashboard creado en Grafana
- [ ] Panels muestran datos correctamente

---

## Recursos

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Prometheus Client Python](https://github.com/prometheus/client_python)
- [Prometheus Queries](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Grafana Dashboard JSON](https://grafana.com/docs/grafana/latest/dashboards/json-model/)

---

## Contacto

Para dudas o soporte con la integraciÃ³n:
- Owner: Cristian Bonelo
- Team: observabilidad
- Environment: QAS

---

**Ãšltimo actualizado**: 2026-04-23
**VersiÃ³n**: 1.0.0
**Estado**: En ProducciÃ³n
