locals {
  agent_image = "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_registry_repo}/ops-agent:${var.image_tag}"
}

# Internal ops agent. HTTPS URL exists, but callers must be authenticated
# (see iam.tf). Unlike Project 1 public-api, we never grant allUsers invoker.

resource "google_cloud_run_v2_service" "ops_agent" {
  name     = "ops-agent"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.ops_agent.email

    scaling {
      min_instance_count = 0
      max_instance_count = 3
    }

    containers {
      image = local.agent_image

      env {
        name  = "GCP_PROJECT"
        value = var.project_id
      }

      env {
        name  = "REGION"
        value = var.region
      }

      env {
        name  = "MODEL"
        value = var.model
      }

      ports {
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }
  }

  depends_on = [
    google_project_service.apis,
    google_artifact_registry_repository.ai_agent,
    google_project_iam_member.ops_agent_run_viewer,
    google_project_iam_member.ops_agent_logging_viewer,
    google_project_iam_member.ops_agent_aiplatform_user,
  ]
}
