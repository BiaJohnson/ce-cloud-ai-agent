# Runtime identity for the Cloud Run agent (like an IAM role on a Lambda/ECS task).
# Least privilege only — never Owner/Editor.

resource "google_service_account" "ops_agent" {
  account_id   = "sa-ops-agent"
  display_name = "Ops agent Cloud Run runtime"
  description  = "Runs ops-agent; read-only tools + Vertex; no Owner/Editor"
}

# Tool: list Cloud Run services
resource "google_project_iam_member" "ops_agent_run_viewer" {
  project = var.project_id
  role    = "roles/run.viewer"
  member  = "serviceAccount:${google_service_account.ops_agent.email}"
}

# Tool: recent error logs
resource "google_project_iam_member" "ops_agent_logging_viewer" {
  project = var.project_id
  role    = "roles/logging.viewer"
  member  = "serviceAccount:${google_service_account.ops_agent.email}"
}

# Call Vertex AI / Gemini
resource "google_project_iam_member" "ops_agent_aiplatform_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.ops_agent.email}"
}
