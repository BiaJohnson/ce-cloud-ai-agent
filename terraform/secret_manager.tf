# Demo hygiene: config lives in Secret Manager, not in the image or GitHub.
# Value is intentionally non-sensitive for this PoC; the pattern is the point.

resource "google_secret_manager_secret" "demo_config" {
  secret_id = "demo-config"

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret_version" "demo_config" {
  secret = google_secret_manager_secret.demo_config.id
  secret_data = jsonencode({
    allowed_project = var.project_id
    feature_flag    = "ops-agent-demo"
  })
}

# Resource-level IAM: only sa-ops-agent can read this secret
resource "google_secret_manager_secret_iam_member" "ops_agent_accessor" {
  secret_id = google_secret_manager_secret.demo_config.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.ops_agent.email}"
}
