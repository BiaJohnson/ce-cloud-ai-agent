resource "google_artifact_registry_repository" "ai_agent" {
  location      = var.region
  repository_id = var.artifact_registry_repo
  description   = "Cloud AI agent PoC images"
  format        = "DOCKER"

  depends_on = [google_project_service.apis]
}
