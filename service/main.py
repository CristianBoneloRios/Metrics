"""
Servicio CODSP Integración - Cristian Bonelo
Team: observabilidad | Project: onboarding-qas
connected to CODSP QAS at http://10.164.10.137:8000
Entorno: QAS | IP CODSP: 10.164.10.137
"""

from contextlib import asynccontextmanager
import asyncio
import random
from fastapi import FastAPI, HTTPException, Query
from fastapi.responses import JSONResponse
from prometheus_fastapi_instrumentator import Instrumentator
import uvicorn

from metrics import register_custom_metrics, SERVICE_INFO
from business import (
    process_document,
    call_external_api,
    process_background_task,
    execute_ai_agent
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan manager para inicializar métricas"""
    register_custom_metrics()
    print("[SUCCESS] Servicio CODSP Integración iniciado - Cristian Bonelo")
    print("[INFO] Team: observabilidad | Project: onboarding-qas")
    print("[INFO] Métricas disponibles en: http://localhost:8080/metrics")
    print("[INFO] Conectando a CODSP QAS: 10.164.10.137")
    yield
    print("[INFO] Servicio detenido")


app = FastAPI(
    title="Servicio CODSP Integración",
    description="Servicio de onboarding para CODSP QAS - Cristian Bonelo",
    version="1.0.0",
    lifespan=lifespan
)


# ==================== ENDPOINTS DE NEGOCIO ====================

@app.get("/")
async def root():
    """Endpoint raíz con información del servicio"""
    return {
        "service": "servicio-codsp-integracion",
        "owner": "Cristian Bonelo",
        "team": "observabilidad",
        "project": "onboarding-qas",
        "environment": "qas",
        "codsp_endpoint": "http://10.164.10.137:8000",
        "prometheus_endpoint": "http://10.164.10.137:9090",
        "grafana_endpoint": "http://10.164.10.137:3000"
    }


@app.get("/health")
@app.get("/health/live")
@app.get("/health/ready")
async def health():
    """Health checks para CODSP"""
    return {"status": "healthy", "owner": "Cristian Bonelo"}


@app.post("/documents/process")
async def api_process_document(document_name: str, doc_type: str, size_bytes: int = 10240):
    """Procesa un documento real con métricas"""
    result = process_document(document_name, doc_type, size_bytes)
    
    if result["status"] == "error":
        raise HTTPException(status_code=500, detail=result["error"])
    
    return result


@app.get("/external/call/{service}/{endpoint}")
async def api_external_call(service: str, endpoint: str):
    """Llama a API externa simulada con métricas"""
    result = await call_external_api(service, endpoint)
    return result


@app.post("/background/task")
async def api_background_task(task_type: str, duration_seconds: float = 0.5):
    """Ejecuta tarea en background con métricas"""
    result = await process_background_task(task_type, duration_seconds)
    return result


@app.post("/ai/execute")
async def api_ai_execute(agent_type: str, input_data: str):
    """Ejecuta agente IA con métricas"""
    result = await execute_ai_agent(agent_type, input_data)
    return result


@app.post("/batch/operations")
async def api_batch_operations(count: int = Query(10, ge=1, le=1000)):
    """Ejecuta lote de operaciones para generar tráfico masivo"""
    results = []
    
    for i in range(count):
        result = process_document(
            document_name=f"batch_doc_{i}",
            doc_type="batch",
            size_bytes=random.randint(1024, 1048576)
        )
        results.append(result)
        
        if i % 5 == 0:
            await call_external_api("batch-service", "process")
    
    return {
        "total": count,
        "successful": len([r for r in results if r["status"] == "ok"]),
        "failed": len([r for r in results if r["status"] == "error"]),
        "results": results[:5]  # primeros 5
    }


# ==================== MÉTRICAS ====================

# Instrumentador automático para métricas HTTP
instrumentator = Instrumentator(
    should_group_status_codes=True,
    should_ignore_untemplated=True,
    should_instrument_requests_inprogress=True,
    excluded_handlers=["/metrics", "/health", "/health/live", "/health/ready"],
)

instrumentator.instrument(app)
instrumentator.expose(app, endpoint="/metrics", include_in_schema=False)


# ==================== EJECUCIÓN DIRECTA ====================

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8080,
        reload=False,
        log_level="info"
    )