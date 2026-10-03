"""Read-only ops tools for the internal ops agent."""
from __future__ import annotations

import os
from typing import Any

from google.cloud import logging_v2
from google.cloud.run_v2 import ServicesClient
from google.cloud.run_v2.types import ListServicesRequest

# Authoritative project/region come from Cloud Run env vars, not Gemini.
PROJECT = os.environ.get("GCP_PROJECT", "")
REGION = os.environ.get("REGION", "us-central1")
MAX_LOG_CHARS = 500


def list_cloud_run_services() -> dict[str, Any]:
    """List Cloud Run services in the configured project and region. Read-only."""
    if not PROJECT:
        return {"error": "GCP_PROJECT is not set"}

    client = ServicesClient()
    parent = f"projects/{PROJECT}/locations/{REGION}"
    services = []
    for service in client.list_services(request=ListServicesRequest(parent=parent)):
        services.append(
            {
                "name": service.name.split("/")[-1],
                "uri": service.uri,
                "generation": service.generation,
            }
        )
    return {"project": PROJECT, "region": REGION, "services": services}


def recent_error_logs(filter: str | None = None, limit: int = 10) -> dict[str, Any]:
    """Fetch recent ERROR log entries from the configured project. Truncated."""
    if not PROJECT:
        return {"error": "GCP_PROJECT is not set"}

    limit = max(1, min(int(limit), 20))
    filter_ = filter or "severity>=ERROR"
    client = logging_v2.Client(project=PROJECT)
    entries = client.list_entries(
        filter_=filter_,
        order_by=logging_v2.DESCENDING,
        max_results=limit,
    )
    results = []
    for entry in entries:
        payload = entry.payload
        message = str(payload)[:MAX_LOG_CHARS]
        results.append(
            {
                "timestamp": (
                    entry.timestamp.isoformat()
                    if entry.timestamp
                    else None
                ),
                "severity": entry.severity,
                "resource": entry.resource.type if entry.resource else None,
                "message": message,
            }
        )
    return {"project": PROJECT, "filter": filter_, "entries": results}


# Registry used by the chat loop — keep this allowlist tiny on purpose.
TOOL_FUNCTIONS = {
    "list_cloud_run_services": list_cloud_run_services,
    "recent_error_logs": recent_error_logs,
}
