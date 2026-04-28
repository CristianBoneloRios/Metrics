# GitHub Pages Metrics Guide

Este repositorio queda preparado para publicar un endpoint de métricas estático y scrapeable desde GitHub Pages.

## Qué hace esta solución

- Genera un archivo [docs/metrics.prom](docs/metrics.prom) en formato Prometheus.
- Mantiene contadores monotónicos para que dashboards con `rate(...)` muestren actividad real.
- Actualiza el archivo cada 10 minutos con GitHub Actions usando [.github/workflows/refresh-static-metrics.yml](.github/workflows/refresh-static-metrics.yml).
- Publica métricas HTTP y métricas de negocio `codsp_*` compatibles con el servicio actual.

## Archivos clave

- [scripts/generate_metrics_prom.py](scripts/generate_metrics_prom.py): genera el archivo Prometheus.
- [scripts/metrics_state.json](scripts/metrics_state.json): mantiene el estado de contadores entre ejecuciones.
- [docs/metrics.prom](docs/metrics.prom): archivo que debe scrapear Prometheus.
- [docs/.nojekyll](docs/.nojekyll): evita transformaciones innecesarias en GitHub Pages.

## Publicación en GitHub Pages

1. Subir estos cambios al repositorio en GitHub.
2. Ir a `Settings > Pages`.
3. Configurar `Source` como `Deploy from a branch`.
4. Elegir la rama principal y la carpeta `/docs`.
5. Guardar y esperar a que GitHub publique el sitio.

La URL final suele quedar con esta forma:

```text
https://<usuario-o-org>.github.io/<repo>/metrics.prom
```

## Registro en CODSP

Cuando la URL pública responda `200`, el registro recomendado en CODSP es:

```json
{
  "name": "servicio-codsp-integracion",
  "display_name": "Servicio CODSP Integracion",
  "team": "observabilidad",
  "project": "onboarding-qas",
  "environment": "qas",
  "targets": ["<usuario-o-org>.github.io:443"],
  "metrics_path": "/<repo>/metrics.prom",
  "scheme": "https",
  "extra_labels": {
    "owner": "Cristian Bonelo",
    "language": "static",
    "framework": "github-pages",
    "team": "observabilidad",
    "project": "onboarding-qas",
    "environment": "qas"
  }
}
```

## Qué paneles del dashboard deberían poblarse

Con este archivo, el dashboard genérico generado por CODSP puede poblar:

- `Service Status`: depende del scrape de Prometheus. `up` lo genera Prometheus, no el archivo.
- `Error Rate (5m)`: usa `http_requests_total` con `status=5xx`.
- `Request Rate by Handler`: usa `http_requests_total` por `handler`.
- `P95 Latency by Handler`: usa `http_request_duration_seconds_bucket`.

Además, el archivo publica métricas de negocio adicionales:

- `codsp_operations_total`
- `codsp_operation_duration_seconds`
- `codsp_documents_processed_total`
- `codsp_document_size_bytes`
- `codsp_external_api_calls_total`
- `codsp_external_api_duration_seconds`
- `codsp_queue_tasks_total`
- `codsp_active_tasks`
- `codsp_ai_executions_total`
- `codsp_ai_execution_duration_seconds`

## Limitaciones importantes

- GitHub Pages sirve un archivo estático, no un proceso vivo.
- Las métricas de tasa y error solo mostrarán movimiento si el workflow sigue actualizando contadores.
- Si se detiene el workflow o deja de publicarse el archivo, `up` volverá a fallar.
- Para observabilidad real en tiempo casi real, conviene mover luego el servicio a un host accesible desde QAS.