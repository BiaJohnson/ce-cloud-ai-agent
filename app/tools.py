"""Read-only ops tools for the internal ops agent."""
from __future__ import annotations
import os
from typing import Any
from google.cloud import logging_v2
from google.cloud.run_v2 import ServicesClient
from google.cloud.run_v2.types import ListServicesRequest
PROJECT = os.environ.get("GCP_PROJECT", "")
REGION = os.environ.get("REGION", "us-central1")
MAX_LOG_CHARS = 500
def list_cloud_run_services(project: str | None = None, region: str | None = None) -> dict[str, Any]:
    """List Cloud Run services (name, uri, generation). Read-only."""
    project = project or PROJECT
    region = region or REGION
    if not project:
        return {"error": "GCP_PROJECT is not set"}
    parent = f"projects/{project}/locations/{region}"
    client = ServicesClient()
    services = []
    for svc in client.list_services(request=ListServicesRequest(parent=parent)):
        services.append(
            {
                "name": svc.name.split("/")[-1],
                "uri": svc.uri,
                "generation": svc.generation,
            }
        )
    return {"project": project, "region": region, "services": services}
def recent_error_logs(
    project: str | None = None,
    filter: str | None = None,
    limit: int = 10,
) -> dict[str, Any]:
    """Fetch a few recent ERROR log entries. Truncated; no secret dumping."""
    project = project or PROJECT
    limit = max(1, min(int(limit), 20))
    log_filter = filter or 'severity>=ERROR'
    client = logging_v2.Client(project=project)
    entries = []
    for entry in client.list_entries(filter_=log_filter, order_by=logging_v2.DESCENDING, max_results=limit):
        payload = entry.payload
        if isinstance(payload, dict):
            text = str(payload)
        else:
            text = str(payload)
        entries.append(
            {
                "timestamp": entry.timestamp.isoformat() if entry.timestamp else None,
                "severity": entry.severity,
                "resource": getattr(entry.resource, "type", None),
                "message": text[:MAX_LOG_CHARS],
            }
        )
    return {"project": project, "filter": log_filter, "entries": entries}
# Registry used by the chat loop — keep this allowlist tiny on purpose.
TOOL_FUNCTIONS = {
    "list_cloud_run_services": list_cloud_run_services,
    "recent_error_logs": recent_error_logs,
}