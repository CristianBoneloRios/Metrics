# Servicio CODSP Integración

Servicio de integración para onboarding en CODSP QAS con instrumentación de Prometheus y métricas de observabilidad.

**Autor**: Cristian Bonelo | **Team**: observabilidad | **Proyecto**: onboarding-qas

## Descripción General

Este es un servicio FastAPI que proporciona una capa de integración con CODSP QAS. Incluye:

- Endpoints RESTful para procesamiento de documentos, llamadas a APIs externas, tareas background y ejecución de agentes IA
- Instrumentación completa con Prometheus para observabilidad
- Métricas de negocio personalizadas
- Simulación realista de operaciones con manejo robusto de errores
- Health checks para Kubernetes/orchestración
- Validación de parámetros con límites de seguridad

## Características

### Endpoints Disponibles

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/` | Información del servicio |
| GET | `/health` | Health checks (live, ready) |
| POST | `/documents/process` | Procesa documentos con métricas |
| GET | `/external/call/{service}/{endpoint}` | Simula llamadas a APIs externas |
| POST | `/background/task` | Ejecuta tareas en background |
| POST | `/ai/execute` | Ejecuta agentes IA |
| POST | `/batch/operations` | Procesa lotes de operaciones (max 1000) |
| GET | `/metrics` | Endpoint de Prometheus |

### Métricas de Prometheus

**Métricas de Negocio:**
- `codsp_operations_total` - Total de operaciones procesadas
- `codsp_operation_duration_seconds` - Duración de operaciones
- `codsp_documents_processed_total` - Total de documentos procesados
- `codsp_document_size_bytes` - Tamaño de documentos
- `codsp_external_api_calls_total` - Llamadas a APIs externas
- `codsp_external_api_duration_seconds` - Duración de llamadas externas
- `codsp_queue_tasks_total` - Tareas procesadas
- `codsp_active_tasks` - Tareas activas actualmente
- `codsp_ai_executions_total` - Ejecuciones de IA
- `codsp_ai_execution_duration_seconds` - Duración de ejecuciones IA

## Instalación y Uso

### Instalación Rápida

```powershell
# Primera vez: instalar Python y dependencias
.\setup.ps1 -Action install

# Ejecutar el servicio
.\setup.ps1 -Action run
```

### Sin Script (Manual)

```powershell
# Instalar Python 3.11+ desde https://www.python.org/downloads/

# Instalar dependencias
pip install -r service/requirements.txt

# Ejecutar servicio
cd service
python main.py
```

El servicio estará disponible en: **http://localhost:8080**

## Estructura del Proyecto

```
codsp-onboarding/
├── setup.ps1                          # Script de instalación/ejecución
├── SETUP_GUIDE.md                     # Guía detallada
├── README.md                          # Este archivo
├── service/
│   ├── main.py                        # Aplicación FastAPI principal
│   ├── business.py                    # Lógica de negocio con métricas
│   ├── metrics.py                     # Definición de métricas Prometheus
│   ├── requirements.txt                # Dependencias Python
│   ├── run.ps1                        # Script de ejecución legacy
│   └── run.bat                        # Batch de ejecución legacy
├── onboarding/                         # Scripts de onboarding
│   ├── 01_get_token.ps1
│   ├── 02_register_service.ps1
│   ├── 03_verify_prometheus.ps1
│   ├── 04_query_metrics.ps1
│   ├── 05_create_dashboard.ps1
│   └── 06_export_dashboard.ps1
├── dashboard/
│   └── grafana_dashboard_cristian_bonelo.json
└── INTEGRATION_GUIDE.md
```

## Dependencias

- **FastAPI** 0.104.1 - Framework web moderno y rápido
- **Uvicorn** 0.24.0 - Servidor ASGI de alto rendimiento
- **Prometheus Client** 0.19.0 - Cliente Prometheus
- **Prometheus FastAPI Instrumentator** 6.1.0 - Instrumentación automática
- **httpx** 0.25.1 - Cliente HTTP async

## Ejemplos de Uso

### 1. Health Check

```bash
curl http://localhost:8080/health
```

Respuesta:
```json
{"status": "healthy", "owner": "Cristian Bonelo"}
```

### 2. Procesar Documento

```bash
curl -X POST "http://localhost:8080/documents/process?document_name=ejemplo.pdf&doc_type=pdf&size_bytes=50000"
```

### 3. Llamar API Externa

```bash
curl "http://localhost:8080/external/call/codsp-api/integration"
```

### 4. Tarea en Background

```bash
curl -X POST "http://localhost:8080/background/task?task_type=export&duration_seconds=2"
```

### 5. Batch de Operaciones

```bash
curl -X POST "http://localhost:8080/batch/operations?count=50"
```

### 6. Ver Métricas Prometheus

```bash
curl http://localhost:8080/metrics
```

## Configuración

### Información del Servicio

- **Host**: 0.0.0.0 (Accesible desde cualquier interface)
- **Puerto**: 8080
- **CODSP QAS IP**: 10.164.10.137
- **Prometheus**: http://10.164.10.137:9090
- **Grafana**: http://10.164.10.137:3000

### Variables de Entorno (Futuro)

Actualmente configurado por defecto. Se pueden agregar:
- `CODSP_HOST` - Host de CODSP QAS
- `CODSP_PORT` - Puerto de CODSP
- `SERVICE_PORT` - Puerto del servicio (default 8080)

## Validaciones y Seguridad

- Límite máximo de 1000 operaciones en `/batch/operations`
- Validación de tamaño de documentos (máximo 100MB)
- Manejo robusto de excepciones
- Códigos de error HTTP apropiados (500 para errores)
- Logs de INFO para auditoría

## Solución de Problemas

### Python no está instalado

Ejecuta: `.\setup.ps1 -Action install`

El script intentará instalarlo desde Microsoft Store automáticamente.

### "No se puede cargar el archivo setup.ps1"

Ejecuta primero:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Puerto 8080 ya está en uso

Modifica el puerto en `service/main.py`, línea de `uvicorn.run()`:
```python
port=8081  # Cambiar a otro puerto disponible
```

### Las dependencias no instalan correctamente

Reinstala todo:
```powershell
.\setup.ps1 -Action reinstall
```

## Contribución

Este es un proyecto de onboarding. Para cambios:

1. Crea una rama: `git checkout -b feature/tu-feature`
2. Haz commit: `git commit -m "Agrega tu-feature"`
3. Push: `git push origin feature/tu-feature`
4. Abre un Pull Request

## Licencia

Proyecto interno - Team observabilidad

## Contacto

**Owner**: Cristian Bonelo  
**Team**: observabilidad  
**Slack**: [Team observabilidad]

## Historial de Cambios

### v1.0.0 (Actual)

- Endpoints iniciales funcionales
- Instrumentación completa con Prometheus
- Health checks
- Validaciones de seguridad
- Scripts de instalación automatizados
- Documentación completa

---

**Última actualización**: Abril 2026  
**Estado**: Production Ready
