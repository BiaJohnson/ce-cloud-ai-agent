variable "project_id" {
  description = "GCP project ID (immutable string, e.g. your-gcp-project-id)"
  type        = string
}

variable "region" {
  description = "Region for Cloud Run, Artifact Registry, and Vertex AI"
  type        = string
  default     = "us-central1"
}

variable "artifact_registry_repo" {
  description = "Artifact Registry Docker repository ID"
  type        = string
  default     = "ai-agent"
}

variable "image_tag" {
  description = "Container image tag for the ops agent (must already exist in Artifact Registry)"
  type        = string
  default     = "v1"
}

variable "model" {
  description = "Vertex AI Gemini model id used by the agent"
  type        = string
  default     = "gemini-2.5-flash"
}

variable "demo_invoker_members" {
  description = <<-EOT
    Principals granted roles/run.invoker on the agent Cloud Run service.
    Use user:you@example.com (or group:...). Never use allUsers for this PoC.
  EOT
  type        = list(string)
}
