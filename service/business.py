"""
Lógica de negocio real con instrumentación
Cristian Bonelo - CODSP Onboarding
"""

import time
import random
import asyncio
from metrics import (
    OPERATIONS_TOTAL,
    OPERATION_DURATION,
    DOCUMENTS_PROCESSED,
    DOCUMENT_SIZE_BYTES,
    EXTERNAL_API_CALLS,
    EXTERNAL_API_DURATION,
    QUEUE_TASKS_TOTAL,
    ACTIVE_TASKS,
    AI_EXECUTIONS_TOTAL,
    AI_EXECUTION_DURATION
)


def process_document(document_name: str, doc_type: str, size_bytes: int) -> dict:
    """Procesa un documento real con métricas"""
    start_time = time.time()
    status = "error"
    
    try:
        # Simular procesamiento
        if size_bytes > 100_000_000:
            raise ValueError("Documento demasiado grande")
        
        time.sleep(random.uniform(0.05, 0.3))
        
        # Simular éxito aleatorio (95% éxito)
        if random.random() < 0.05:
            raise Exception("Error temporal en procesamiento")
        
        status = "success"
        
        OPERATIONS_TOTAL.labels(
            operation_type="document_processing",
            status=status,
            owner="cristian_bonelo"
        ).inc()
        
        DOCUMENTS_PROCESSED.labels(
            doc_type=doc_type,
            status=status,
            owner="cristian_bonelo"
        ).inc()
        
        DOCUMENT_SIZE_BYTES.labels(doc_type=doc_type).observe(size_bytes)
        
        return {
            "status": "ok",
            "document": document_name,
            "processed_size": size_bytes,
            "processing_time": round(time.time() - start_time, 3)
        }
        
    except Exception as e:
        OPERATIONS_TOTAL.labels(
            operation_type="document_processing",
            status="error",
            owner="cristian_bonelo"
        ).inc()
        
        DOCUMENTS_PROCESSED.labels(
            doc_type=doc_type,
            status="error",
            owner="cristian_bonelo"
        ).inc()
        
        return {
            "status": "error",
            "document": document_name,
            "error": str(e)
        }
        
    finally:
        OPERATION_DURATION.labels(
            operation_type="document_processing"
        ).observe(time.time() - start_time)


async def call_external_api(service: str, endpoint: str) -> dict:
    """Simula llamada a API externa con métricas"""
    start_time = time.time()
    status = "success"
    
    try:
        # Simular latencia de API externa
        await asyncio.sleep(random.uniform(0.1, 0.5))
        
        # 5% de error
        if random.random() < 0.05:
            status = "error"
            raise Exception(f"API {service} respondió con error")
        
        return {"status": "ok", "data": f"Response from {service}/{endpoint}"}
        
    except Exception as e:
        status = "error"
        return {
            "status": "error",
            "service": service,
            "endpoint": endpoint,
            "error": str(e)
        }
        
    finally:
        EXTERNAL_API_CALLS.labels(
            service=service,
            endpoint=endpoint,
            status=status
        ).inc()
        
        EXTERNAL_API_DURATION.labels(
            service=service,
            endpoint=endpoint
        ).observe(time.time() - start_time)


async def process_background_task(task_type: str, duration: float) -> dict:
    """Procesa tarea en background con métricas"""
    ACTIVE_TASKS.inc()
    start_time = time.time()
    status = "success"
    
    try:
        await asyncio.sleep(duration)
        
        if random.random() < 0.1:
            status = "error"
            raise Exception("Tarea falló")
        
        return {"status": "ok", "task_type": task_type, "duration": duration}
        
    except Exception as e:
        status = "error"
        return {
            "status": "error",
            "task_type": task_type,
            "error": str(e)
        }
        
    finally:
        QUEUE_TASKS_TOTAL.labels(
            task_type=task_type,
            status=status
        ).inc()
        
        ACTIVE_TASKS.dec()
        OPERATION_DURATION.labels(
            operation_type=f"background_{task_type}"
        ).observe(time.time() - start_time)


async def execute_ai_agent(agent_type: str, input_data: str) -> dict:
    """Simula ejecución de agente IA con métricas"""
    start_time = time.time()
    status = "success"
    
    try:
        await asyncio.sleep(random.uniform(0.5, 1.5))
        
        if random.random() < 0.1:
            status = "error"
            raise Exception("Agente IA falló")
        
        return {
            "status": "ok",
            "agent": agent_type,
            "result": f"Procesado: {input_data[:50]}"
        }
        
    finally:
        AI_EXECUTIONS_TOTAL.labels(
            agent_type=agent_type,
            status=status
        ).inc()
        
        AI_EXECUTION_DURATION.labels(
            agent_type=agent_type
        ).observe(time.time() - start_time)