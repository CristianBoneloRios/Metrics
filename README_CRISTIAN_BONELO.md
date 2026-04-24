# Servicio CODSP IntegraciÃ³n - Cristian Bonelo

## DescripciÃ³n General

Servicio de onboarding y demostraciÃ³n de integraciÃ³n con **CODSP QAS** (plataforma de observabilidad centralizada). Este proyecto implementa un servicio FastAPI con instrumentaciÃ³n completa de Prometheus, mostrando mejores prÃ¡cticas de observabilidad, mÃ©tricas de negocio y monitoreo centralizado.

**Propietario**: Cristian Bonelo  
**Equipo**: observabilidad  
**Proyecto**: onboarding-qas  
**Entorno**: QAS  
**VersiÃ³n**: 1.0.0

---

## Objetivos del Proyecto

- [OK] Demostrar integraciÃ³n de un servicio con CODSP QAS
- [OK] Implementar mÃ©tricas de negocio en Prometheus
- [OK] Crear alertas y dashboards en Grafana
- [OK] Documentar el onboarding completo
- [OK] Generar trÃ¡fico de prueba realista
- [OK] Verificar la observabilidad end-to-end

---

## Estructura del Proyecto

```
codsp-onboarding/
â”œâ”€â”€ README_CRISTIAN_BONELO.md          # Este archivo
â”œâ”€â”€ INTEGRATION_GUIDE.md                # GuÃ­a de integraciÃ³n
â”œâ”€â”€ verify_all.ps1                      # Script de verificaciÃ³n completÃ¡
â”‚
â”œâ”€â”€ service/                            # Servicio FastAPI principal
â”‚   â”œâ”€â”€ main.py                         # AplicaciÃ³n FastAPI
â”‚   â”œâ”€â”€ business.py                     # LÃ³gica de negocio
â”‚   â”œâ”€â”€ metrics.py                      # Definiciones de mÃ©tricas
â”‚   â”œâ”€â”€ requirements.txt                # Dependencias Python
â”‚   â”œâ”€â”€ run.bat                         # Ejecutar en Windows (CMD)
â”‚   â”œâ”€â”€ run.ps1                         # Ejecutar en Windows (PowerShell)
â”‚   â””â”€â”€ test_traffic.bat                # Generar trÃ¡fico de prueba
â”‚
â”œâ”€â”€ onboarding/                         # Scripts de onboarding en CODSP
â”‚   â”œâ”€â”€ 01_get_token.ps1               # 1. Obtener token JWT
â”‚   â”œâ”€â”€ 02_register_service.ps1        # 2. Registrar servicio
â”‚   â”œâ”€â”€ 03_verify_prometheus.ps1       # 3. Verificar target en Prometheus
â”‚   â”œâ”€â”€ 04_query_metrics.ps1           # 4. Consultar mÃ©tricas
â”‚   â””â”€â”€ 05_create_dashboard.ps1        # 5. Crear dashboard en Grafana
â”‚
â””â”€â”€ dashboard/
    â””â”€â”€ grafana_dashboard_cristian_bonelo.json  # Dashboard Grafana exportado
```

---

## Inicio RÃ¡pido

### Requisitos Previos

- **Python 3.9+** instalado
- **pip** (gestor de paquetes Python)
- **CODSP QAS** accesible en: `http://10.164.10.137:8000`
- **Prometheus** accesible en: `http://10.164.10.137:9090`
- **Grafana** accesible en: `http://10.164.10.137:3000`
- Credenciales CODSP QAS: `admin.user` / `admin123`

### InstalaciÃ³n y EjecuciÃ³n

#### OpciÃ³n 1: PowerShell (Recomendado)

```powershell
# Ubicarse en el directorio del servicio
cd C:\\codsp-onboarding\\codsp-onboarding\service

# Ejecutar el servicio
.\run.ps1
```

#### OpciÃ³n 2: CMD (Windows)

```batch
cd C:\\codsp-onboarding\\codsp-onboarding\service
run.bat
```

#### OpciÃ³n 3: Manual con pip

```powershell
cd C:\\codsp-onboarding\\codsp-onboarding\service
pip install -r requirements.txt
python main.py
```

El servicio estarÃ¡ disponible en: **http://localhost:8080**

---

## Endpoints del Servicio

### Health & Info

| MÃ©todo | Endpoint | DescripciÃ³n |
|--------|----------|-------------|
| GET | `/` | InformaciÃ³n del servicio |
| GET | `/health` | Health check bÃ¡sico |
| GET | `/health/live` | Liveness probe |
| GET | `/health/ready` | Readiness probe |
| GET | `/metrics` | MÃ©tricas Prometheus |

### Operaciones de Negocio

| MÃ©todo | Endpoint | DescripciÃ³n | ParÃ¡metros |
|--------|----------|-------------|-----------|
| POST | `/documents/process` | Procesar documento | `document_name`, `doc_type`, `size_bytes` |
| GET | `/external/call/{service}/{endpoint}` | Llamar API externa | - |
| POST | `/background/task` | Ejecutar tarea en background | `task_type`, `duration_seconds` |
| POST | `/ai/execute` | Ejecutar agente IA | `agent_type`, `input_data` |

### Ejemplos de Uso

```bash
# Verificar health
curl http://localhost:8080/health

# Procesar un documento
curl -X POST "http://localhost:8080/documents/process?document_name=informe.pdf&doc_type=pdf&size_bytes=100000"

# Llamar API externa
curl "http://localhost:8080/external/call/storage/upload"

# Ejecutar tarea en background
curl -X POST "http://localhost:8080/background/task?task_type=indexing&duration_seconds=2"

# Ver mÃ©tricas
curl http://localhost:8080/metrics
```

---

## MÃ©tricas Instrumentadas

El servicio registra mÃ©tricas de negocio en Prometheus:

### Operaciones

- **`codsp_operations_total`** (Counter)
  - Labels: `operation_type`, `status`, `owner`
  - Incrementa con cada operaciÃ³n exitosa o fallida

- **`codsp_operation_duration_seconds`** (Histogram)
  - DuraciÃ³n de operaciones en segundos
  - Buckets: 0.01, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0, 30.0, 60.0

### Documentos

- **`codsp_documents_processed_total`** (Counter)
  - Labels: `doc_type`, `status`, `owner`

- **`codsp_document_size_bytes`** (Histogram)
  - TamaÃ±o de documentos procesados

### APIs Externas

- **`codsp_external_api_calls_total`** (Counter)
  - Labels: `service`, `endpoint`, `status`

- **`codsp_external_api_duration_seconds`** (Histogram)
  - Latencia de llamadas a APIs externas

### Tareas en Background

- **`codsp_queue_tasks_total`** (Counter)
  - Tasks encoladas y procesadas
  
- **`codsp_active_tasks`** (Gauge)
  - Tareas activas actualmente

### IA/Agentes

- **`codsp_ai_executions_total`** (Counter)
  - Ejecuciones de agentes IA

- **`codsp_ai_execution_duration_seconds`** (Histogram)
  - DuraciÃ³n de ejecuciones de IA

### HTTP EstÃ¡ndar

- **`http_requests_total`** (Counter)
  - Total de requests HTTP
  
- **`http_request_duration_seconds`** (Histogram)
  - DuraciÃ³n de requests HTTP

---

## Onboarding en CODSP QAS

Ejecutar los scripts en orden:

### 1. Obtener Token
```powershell
cd C:\\codsp-onboarding\\codsp-onboarding\onboarding
.\01_get_token.ps1
```
- Inicia sesiÃ³n en CODSP QAS
- Guarda token en `token.txt`
- VÃ¡lido para prÃ³ximos scripts

### 2. Registrar Servicio
```powershell
.\02_register_service.ps1
```
- Registra el servicio en catÃ¡logo CODSP
- Configura targets de Prometheus
- Labels: owner, team, project, environment, etc.
- El servicio debe estar ejecutÃ¡ndose (`run.ps1`)

### 3. Verificar Target en Prometheus
```powershell
.\03_verify_prometheus.ps1
```
- Verifica que el target estÃ© activo en Prometheus
- Consulta mÃ©trica `up{job="servicio-codsp-integracion"}`
- Comprueba Ãºltimos scrapes

### 4. Consultar MÃ©tricas PromQL
```powershell
.\04_query_metrics.ps1
```
Ejecuta consultas:
- Estado del target
- Tasa de requests HTTP
- Tasa de errores
- Operaciones de negocio
- Documentos procesados
- Llamadas a APIs externas

Exporta resultados en `metrics_results.csv`

### 5. Crear Dashboard en Grafana
```powershell
.\05_create_dashboard.ps1
```
- Importa dashboard en Grafana
- Dashboard JSON: `dashboard/grafana_dashboard_cristian_bonelo.json`
- URL Grafana: `http://10.164.10.137:3000`

---

## Generar TrÃ¡fico de Prueba

```batch
cd C:\\codsp-onboarding\\codsp-onboarding\service
test_traffic.bat
```

Genera:
- 20 documentos procesados
- MÃºltiples llamadas a APIs externas
- Verificaciones de health
- Datos para visualizar en Prometheus/Grafana

---

## VerificaciÃ³n Completa

Script unificado que verifica todo:

```powershell
cd C:\\codsp-onboarding\\codsp-onboarding
.\verify_all.ps1
```

Verifica:
1. [OK] Servicio local en http://localhost:8080/health
2. [OK] Endpoint /metrics disponible
3. [OK] AutenticaciÃ³n con CODSP QAS
4. [OK] Prometheus accesible
5. [OK] Genera 10 documentos de prueba
6. [OK] Resumen final

---

## Dashboard Grafana

**UbicaciÃ³n**: `dashboard/grafana_dashboard_cristian_bonelo.json`

**Paneles incluidos**:
1. **Health Status** - Estado del target (stat)
2. **HTTP Requests Rate (5m)** - Tasa de requests (graph)
3. **HTTP Error Rate (%)** - Porcentaje de errores (graph)
4. **Business Operations** - Operaciones de negocio (graph)
5. **Documents Processed** - Documentos procesados (bargauge)
6. **External API Calls** - Llamadas a APIs externas (piechart)
7. **Operation Duration P95** - P95 de duraciÃ³n (graph)
8. **Service Info** - InformaciÃ³n del servicio (table)

**Importar en Grafana**:
1. Ir a: `http://10.164.10.137:3000` â†’ +New â†’ Import
2. Subir archivo JSON o copiar JSON crudo
3. Seleccionar datasource Prometheus
4. Confirmar

---

## Troubleshooting

### El servicio no inicia

```text
[ERROR] ModuleNotFoundError: No module named 'fastapi'

SoluciÃ³n:
1. pip install -r requirements.txt
2. Asegurar Python 3.9+: python --version
```

### CODSP QAS no responde

```text
[ERROR] No se puede acceder a http://10.164.10.137:8000

SoluciÃ³n:
1. Verificar conectividad: ping 10.164.10.137
2. Verificar firewall
3. Credenciales: admin.user / admin123
```

### Target no aparece en Prometheus

```text
[ERROR] El job "servicio-codsp-integracion" no se ve en Prometheus

SoluciÃ³n:
1. Ejecutar 02_register_service.ps1 nuevamente
2. Esperar 30-60 segundos para scraping
3. Verificar IP local: ipconfig
4. Ver logs en Prometheus: http://10.164.10.137:9090/targets
```

### MÃ©tricas no aparecen

```text
[ERROR] Las mÃ©tricas personalizadas no se ven

SoluciÃ³n:
1. Generar trÃ¡fico: test_traffic.bat
2. Esperar 30 segundos
3. Consultar: http://localhost:8080/metrics
4. Verificar endpoint /metrics contiene "codsp_"
```

---

## Dependencias

```
fastapi==0.104.1
uvicorn==0.24.0
prometheus-client==0.19.0
prometheus-fastapi-instrumentator==6.1.0
httpx==0.25.1
```

Instalar:
```bash
pip install -r service/requirements.txt
```

---

## ConfiguraciÃ³n y Entorno

**Variables importantes** (hardcodeadas en scripts):

| Variable | Valor | DescripciÃ³n |
|----------|-------|-------------|
| CODSP_URL | `http://10.164.10.137:8000` | Endpoint CODSP QAS |
| PROMETHEUS_URL | `http://10.164.10.137:9090` | Endpoint Prometheus |
| GRAFANA_URL | `http://10.164.10.137:3000` | Endpoint Grafana |
| SERVICE_PORT | `8080` | Puerto del servicio local |
| USERNAME | `admin.user` | Usuario CODSP |
| PASSWORD | `admin123` | ContraseÃ±a CODSP |

---

## Referencias

- **FastAPI Documentation**: https://fastapi.tiangolo.com/
- **Prometheus Documentation**: https://prometheus.io/
- **Grafana Documentation**: https://grafana.com/docs/
- **CODSP QAS**: http://10.164.10.137:8000

---

## Contacto y Soporte

- **Propietario**: Cristian Bonelo
- **Equipo**: observabilidad
- **Proyecto**: onboarding-qas

---

## Licencia

Proyecto interno de CODSP QAS - Equipo de Observabilidad

---

## Ãšltimas Actualizaciones

- **v1.0.0** (2026-04-23): VersiÃ³n inicial completa con todos los features

