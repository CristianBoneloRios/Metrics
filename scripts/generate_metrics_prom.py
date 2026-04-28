from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
STATE_PATH = ROOT / "scripts" / "metrics_state.json"
OUTPUT_PATH = ROOT / "docs" / "metrics.prom"

DEFAULT_STATE = {
    "generated_runs": 0,
    "documents_success": 140,
    "documents_error": 8,
    "external_success": 36,
    "external_error": 3,
    "queue_success": 14,
    "queue_error": 1,
    "ai_success": 9,
    "ai_error": 1,
    "last_generated_at": "2026-04-28T00:00:00Z",
}


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def load_state() -> dict:
    if not STATE_PATH.exists():
        return DEFAULT_STATE.copy()

    with STATE_PATH.open("r", encoding="utf-8") as handle:
        data = json.load(handle)

    merged = DEFAULT_STATE.copy()
    merged.update(data)
    return merged


def save_state(state: dict) -> None:
    with STATE_PATH.open("w", encoding="utf-8") as handle:
        json.dump(state, handle, indent=2)
        handle.write("\n")


def bump_state(state: dict) -> dict:
    run = state["generated_runs"] + 1
    state["generated_runs"] = run
    state["documents_success"] += 10 + (run % 4)
    state["documents_error"] += 1 if run % 3 == 0 else 0
    state["external_success"] += 4 + (run % 2)
    state["external_error"] += 1 if run % 5 == 0 else 0
    state["queue_success"] += 2
    state["queue_error"] += 1 if run % 6 == 0 else 0
    state["ai_success"] += 1 + (run % 2)
    state["ai_error"] += 1 if run % 7 == 0 else 0
    state["last_generated_at"] = utc_now()
    return state


def split_total(total: int, first_ratio: float) -> tuple[int, int]:
    first = int(round(total * first_ratio))
    first = max(0, min(first, total))
    return first, total - first


def format_float(value: float) -> str:
    if value == int(value):
        return f"{value:.1f}"
    return f"{value:.6f}".rstrip("0").rstrip(".")


def render_metric(name: str, value: float, labels: dict[str, str] | None = None) -> str:
    if labels:
        label_text = ",".join(f'{key}="{label}"' for key, label in labels.items())
        return f"{name}{{{label_text}}} {format_float(value)}"
    return f"{name} {format_float(value)}"


def cumulative_counts(total: int, fractions: list[float]) -> list[int]:
    values: list[int] = []
    current = 0
    for fraction in fractions:
        target = int(round(total * fraction))
        target = max(current, min(total, target))
        values.append(target)
        current = target
    return values


def render_histogram(
    name: str,
    documentation: str,
    labels: dict[str, str],
    buckets: list[str],
    fractions: list[float],
    count: int,
    total_sum: float,
) -> list[str]:
    lines = [
        f"# HELP {name} {documentation}",
        f"# TYPE {name} histogram",
    ]
    bucket_counts = cumulative_counts(count, fractions)

    for boundary, bucket_count in zip(buckets, bucket_counts):
        bucket_labels = dict(labels)
        bucket_labels["le"] = boundary
        lines.append(render_metric(f"{name}_bucket", bucket_count, bucket_labels))

    inf_labels = dict(labels)
    inf_labels["le"] = "+Inf"
    lines.append(render_metric(f"{name}_bucket", count, inf_labels))
    lines.append(render_metric(f"{name}_count", count, labels))
    lines.append(render_metric(f"{name}_sum", total_sum, labels))
    return lines


def build_metrics(state: dict) -> str:
    generated_at = state["last_generated_at"]
    documents_success = state["documents_success"]
    documents_error = state["documents_error"]
    documents_total = documents_success + documents_error
    external_success = state["external_success"]
    external_error = state["external_error"]
    external_total = external_success + external_error
    queue_success = state["queue_success"]
    queue_error = state["queue_error"]
    queue_total = queue_success + queue_error
    ai_success = state["ai_success"]
    ai_error = state["ai_error"]
    ai_total = ai_success + ai_error

    invoice_success, contract_success = split_total(documents_success, 0.64)
    invoice_error, contract_error = split_total(documents_error, 0.5)
    payments_success, catalog_success = split_total(external_success, 0.72)
    payments_error, catalog_error = split_total(external_error, 0.35)
    reindex_success, sync_success = split_total(queue_success, 0.7)
    reindex_error, sync_error = split_total(queue_error, 0.5)
    summarizer_success, classifier_success = split_total(ai_success, 0.67)
    summarizer_error, classifier_error = split_total(ai_error, 0.25)

    doc_duration_buckets = ["0.01", "0.05", "0.1", "0.25", "0.5", "1.0", "2.5", "5.0", "10.0", "30.0", "60.0"]
    doc_duration_fractions = [0.0, 0.08, 0.26, 0.84, 0.98, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
    document_size_buckets = ["1024.0", "10240.0", "102400.0", "1.048576e+06", "1.048576e+07", "1.048576e+08"]
    document_size_fractions = [0.0, 0.18, 0.88, 1.0, 1.0, 1.0]
    external_duration_buckets = ["0.1", "0.5", "1.0", "2.0", "5.0", "10.0", "30.0"]
    external_duration_fractions = [0.04, 0.82, 0.96, 1.0, 1.0, 1.0, 1.0]
    ai_duration_buckets = ["1.0", "5.0", "10.0", "30.0", "60.0", "120.0", "300.0"]
    ai_duration_fractions = [0.32, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
    http_duration_buckets = ["0.05", "0.1", "0.25", "0.5", "1.0", "2.5", "5.0"]

    lines = [
        "# Static Prometheus exposition for GitHub Pages.",
        "# Generated automatically by scripts/generate_metrics_prom.py.",
        f"# generated_at {generated_at}",
        "# Note: Prometheus generates the up{} metric during scraping; it is not defined here.",
        "",
        "# HELP codsp_service_info Informacion del servicio CODSP publicada desde GitHub Pages",
        "# TYPE codsp_service_info gauge",
        render_metric(
            "codsp_service_info",
            1,
            {
                "environment": "qas",
                "owner": "Cristian Bonelo",
                "project": "onboarding-qas",
                "service": "servicio-codsp-integracion",
                "team": "observabilidad",
            },
        ),
        "",
        "# HELP codsp_operations_total Total de operaciones procesadas",
        "# TYPE codsp_operations_total counter",
        render_metric(
            "codsp_operations_total",
            documents_success,
            {"operation_type": "document_processing", "owner": "cristian_bonelo", "status": "success"},
        ),
        render_metric(
            "codsp_operations_total",
            documents_error,
            {"operation_type": "document_processing", "owner": "cristian_bonelo", "status": "error"},
        ),
        "",
    ]

    lines.extend(
        render_histogram(
            "codsp_operation_duration_seconds",
            "Duracion de operaciones en segundos",
            {"operation_type": "document_processing"},
            doc_duration_buckets,
            doc_duration_fractions,
            documents_total,
            documents_total * 0.183,
        )
    )
    lines.extend(
        render_histogram(
            "codsp_operation_duration_seconds",
            "Duracion de operaciones en segundos",
            {"operation_type": "background_reindex"},
            doc_duration_buckets,
            [0.0, 0.0, 0.08, 0.92, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0],
            queue_total,
            queue_total * 0.228,
        )
    )

    lines.extend(
        [
            "",
            "# HELP codsp_documents_processed_total Total de documentos procesados",
            "# TYPE codsp_documents_processed_total counter",
            render_metric(
                "codsp_documents_processed_total",
                invoice_success,
                {"doc_type": "invoice", "owner": "cristian_bonelo", "status": "success"},
            ),
            render_metric(
                "codsp_documents_processed_total",
                contract_success,
                {"doc_type": "contract", "owner": "cristian_bonelo", "status": "success"},
            ),
            render_metric(
                "codsp_documents_processed_total",
                invoice_error,
                {"doc_type": "invoice", "owner": "cristian_bonelo", "status": "error"},
            ),
            render_metric(
                "codsp_documents_processed_total",
                contract_error,
                {"doc_type": "contract", "owner": "cristian_bonelo", "status": "error"},
            ),
            "",
        ]
    )

    lines.extend(
        render_histogram(
            "codsp_document_size_bytes",
            "Tamano de documentos en bytes",
            {"doc_type": "invoice"},
            document_size_buckets,
            document_size_fractions,
            invoice_success,
            invoice_success * 18240,
        )
    )
    lines.extend(
        render_histogram(
            "codsp_document_size_bytes",
            "Tamano de documentos en bytes",
            {"doc_type": "contract"},
            document_size_buckets,
            [0.0, 0.12, 0.72, 1.0, 1.0, 1.0],
            contract_success,
            contract_success * 46800,
        )
    )

    lines.extend(
        [
            "",
            "# HELP codsp_external_api_calls_total Total de llamadas a APIs externas",
            "# TYPE codsp_external_api_calls_total counter",
            render_metric(
                "codsp_external_api_calls_total",
                payments_success,
                {"endpoint": "status", "service": "payments", "status": "success"},
            ),
            render_metric(
                "codsp_external_api_calls_total",
                catalog_success,
                {"endpoint": "register", "service": "catalog", "status": "success"},
            ),
            render_metric(
                "codsp_external_api_calls_total",
                payments_error,
                {"endpoint": "status", "service": "payments", "status": "error"},
            ),
            render_metric(
                "codsp_external_api_calls_total",
                catalog_error,
                {"endpoint": "register", "service": "catalog", "status": "error"},
            ),
            "",
        ]
    )

    lines.extend(
        render_histogram(
            "codsp_external_api_duration_seconds",
            "Duracion de llamadas a APIs externas",
            {"endpoint": "status", "service": "payments"},
            external_duration_buckets,
            external_duration_fractions,
            payments_success + payments_error,
            (payments_success + payments_error) * 0.364,
        )
    )
    lines.extend(
        render_histogram(
            "codsp_external_api_duration_seconds",
            "Duracion de llamadas a APIs externas",
            {"endpoint": "register", "service": "catalog"},
            external_duration_buckets,
            [0.02, 0.74, 0.94, 1.0, 1.0, 1.0, 1.0],
            catalog_success + catalog_error,
            (catalog_success + catalog_error) * 0.621,
        )
    )

    lines.extend(
        [
            "",
            "# HELP codsp_queue_tasks_total Total de tareas en cola procesadas",
            "# TYPE codsp_queue_tasks_total counter",
            render_metric(
                "codsp_queue_tasks_total",
                reindex_success,
                {"status": "success", "task_type": "reindex"},
            ),
            render_metric(
                "codsp_queue_tasks_total",
                sync_success,
                {"status": "success", "task_type": "sync"},
            ),
            render_metric(
                "codsp_queue_tasks_total",
                reindex_error,
                {"status": "error", "task_type": "reindex"},
            ),
            render_metric(
                "codsp_queue_tasks_total",
                sync_error,
                {"status": "error", "task_type": "sync"},
            ),
            "",
            "# HELP codsp_active_tasks Tareas activas actualmente",
            "# TYPE codsp_active_tasks gauge",
            render_metric("codsp_active_tasks", state["generated_runs"] % 3),
            "",
            "# HELP codsp_ai_executions_total Total de ejecuciones de IA/agentes",
            "# TYPE codsp_ai_executions_total counter",
            render_metric(
                "codsp_ai_executions_total",
                summarizer_success,
                {"agent_type": "summarizer", "status": "success"},
            ),
            render_metric(
                "codsp_ai_executions_total",
                classifier_success,
                {"agent_type": "classifier", "status": "success"},
            ),
            render_metric(
                "codsp_ai_executions_total",
                summarizer_error,
                {"agent_type": "summarizer", "status": "error"},
            ),
            render_metric(
                "codsp_ai_executions_total",
                classifier_error,
                {"agent_type": "classifier", "status": "error"},
            ),
            "",
        ]
    )

    lines.extend(
        render_histogram(
            "codsp_ai_execution_duration_seconds",
            "Duracion de ejecuciones de IA",
            {"agent_type": "summarizer"},
            ai_duration_buckets,
            ai_duration_fractions,
            summarizer_success + summarizer_error,
            (summarizer_success + summarizer_error) * 1.24,
        )
    )
    lines.extend(
        render_histogram(
            "codsp_ai_execution_duration_seconds",
            "Duracion de ejecuciones de IA",
            {"agent_type": "classifier"},
            ai_duration_buckets,
            [0.18, 0.96, 1.0, 1.0, 1.0, 1.0, 1.0],
            classifier_success + classifier_error,
            (classifier_success + classifier_error) * 0.86,
        )
    )

    lines.extend(
        [
            "",
            "# HELP http_requests_total Total number of requests by method, status and handler.",
            "# TYPE http_requests_total counter",
            render_metric(
                "http_requests_total",
                documents_success,
                {"handler": "/documents/process", "method": "POST", "status": "2xx"},
            ),
            render_metric(
                "http_requests_total",
                documents_error,
                {"handler": "/documents/process", "method": "POST", "status": "5xx"},
            ),
            render_metric(
                "http_requests_total",
                external_total,
                {"handler": "/external/call/{service}/{endpoint}", "method": "GET", "status": "2xx"},
            ),
            render_metric(
                "http_requests_total",
                queue_total,
                {"handler": "/background/task", "method": "POST", "status": "2xx"},
            ),
            render_metric(
                "http_requests_total",
                ai_total,
                {"handler": "/ai/execute", "method": "POST", "status": "2xx"},
            ),
            render_metric(
                "http_requests_total",
                max(4, state["generated_runs"] * 3),
                {"handler": "/batch/operations", "method": "POST", "status": "2xx"},
            ),
            "",
        ]
    )

    lines.extend(
        render_histogram(
            "http_request_duration_seconds",
            "Latency by handler for GitHub Pages static metrics",
            {"handler": "/documents/process", "method": "POST"},
            http_duration_buckets,
            [0.04, 0.22, 0.9, 1.0, 1.0, 1.0, 1.0],
            documents_total,
            documents_total * 0.191,
        )
    )
    lines.extend(
        render_histogram(
            "http_request_duration_seconds",
            "Latency by handler for GitHub Pages static metrics",
            {"handler": "/external/call/{service}/{endpoint}", "method": "GET"},
            http_duration_buckets,
            [0.02, 0.08, 0.34, 0.86, 1.0, 1.0, 1.0],
            external_total,
            external_total * 0.438,
        )
    )
    lines.extend(
        render_histogram(
            "http_request_duration_seconds",
            "Latency by handler for GitHub Pages static metrics",
            {"handler": "/background/task", "method": "POST"},
            http_duration_buckets,
            [0.0, 0.0, 0.08, 0.92, 1.0, 1.0, 1.0],
            queue_total,
            queue_total * 0.229,
        )
    )
    lines.extend(
        render_histogram(
            "http_request_duration_seconds",
            "Latency by handler for GitHub Pages static metrics",
            {"handler": "/ai/execute", "method": "POST"},
            http_duration_buckets,
            [0.0, 0.02, 0.12, 0.42, 1.0, 1.0, 1.0],
            ai_total,
            ai_total * 0.934,
        )
    )
    lines.extend(
        render_histogram(
            "http_request_duration_seconds",
            "Latency by handler for GitHub Pages static metrics",
            {"handler": "/batch/operations", "method": "POST"},
            http_duration_buckets,
            [0.0, 0.0, 0.06, 0.38, 0.84, 1.0, 1.0],
            max(4, state["generated_runs"] * 3),
            max(4, state["generated_runs"] * 3) * 0.713,
        )
    )

    return "\n".join(lines) + "\n"


def main() -> None:
    state = bump_state(load_state())
    save_state(state)
    OUTPUT_PATH.write_text(build_metrics(state), encoding="utf-8")
    print(f"Generated {OUTPUT_PATH}")


if __name__ == "__main__":
    main()