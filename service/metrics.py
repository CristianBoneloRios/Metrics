"""
Métricas de negocio para CODSP - Cristian Bonelo
Proyecto: onboarding-qas
Team: observabilidad
"""

from prometheus_client import Counter, Histogram, Gauge, Info

# === Identidad del servicio ===
SERVICE_INFO = Info("codsp_service", "Información del servicio CODSP")
SERVICE_INFO.info({
    "owner": "Cristian Bonelo",
    "team": "observabilidad",
    "project": "onboarding-qas",
    "environment": "qas",
    "service": "servicio-codsp-integracion"
})

# === Métricas de negocio principales ===
OPERATIONS_TOTAL = Counter(
    "codsp_operations_total",
    "Total de operaciones procesadas",
    labelnames=["operation_type", "status", "owner"]
)

OPERATION_DURATION = Histogram(
    "codsp_operation_duration_seconds",
    "Duración de operaciones en segundos",
    labelnames=["operation_type"],
    buckets=(0.01, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0, 30.0, 60.0)
)

# === Métricas de documentos ===
DOCUMENTS_PROCESSED = Counter(
    "codsp_documents_processed_total",
    "Total de documentos procesados",
    labelnames=["doc_type", "status", "owner"]
)

DOCUMENT_SIZE_BYTES = Histogram(
    "codsp_document_size_bytes",
    "Tamaño de documentos en bytes",
    labelnames=["doc_type"],
    buckets=(1024, 10240, 102400, 1048576, 10485760, 104857600)
)

# === Métricas de API externas ===
EXTERNAL_API_CALLS = Counter(
    "codsp_external_api_calls_total",
    "Total de llamadas a APIs externas",
    labelnames=["service", "endpoint", "status"]
)

EXTERNAL_API_DURATION = Histogram(
    "codsp_external_api_duration_seconds",
    "Duración de llamadas a APIs externas",
    labelnames=["service", "endpoint"],
    buckets=(0.1, 0.5, 1.0, 2.0, 5.0, 10.0, 30.0)
)

# === Métricas de cola/background ===
QUEUE_TASKS_TOTAL = Counter(
    "codsp_queue_tasks_total",
    "Total de tareas en cola procesadas",
    labelnames=["task_type", "status"]
)

ACTIVE_TASKS = Gauge(
    "codsp_active_tasks",
    "Tareas activas actualmente"
)

# === Métricas de IA (para integraciones futuras) ===
AI_EXECUTIONS_TOTAL = Counter(
    "codsp_ai_executions_total",
    "Total de ejecuciones de IA/agentes",
    labelnames=["agent_type", "status"]
)

AI_EXECUTION_DURATION = Histogram(
    "codsp_ai_execution_duration_seconds",
    "Duración de ejecuciones de IA",
    labelnames=["agent_type"],
    buckets=(1.0, 5.0, 10.0, 30.0, 60.0, 120.0, 300.0)
)


def register_custom_metrics() -> None:
    """Hook de registro - las métricas se registran en importación"""
    pass