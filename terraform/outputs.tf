output "agent_url" {
  description = "HTTPS URL for the authenticated ops-agent Cloud Run service"
  value       = google_cloud_run_v2_service.ops_agent.uri
}

output "service_account_email" {
  description = "Runtime SA for ops-agent (least-privilege: run.viewer, logging.viewer, aiplatform.user)"
  value       = google_service_account.ops_agent.email
}

output "artifact_registry_repository" {
  description = "Artifact Registry Docker repo hosting the agent image"
  value       = google_artifact_registry_repository.ai_agent.name
}

output "example_curl" {
  description = "Authenticated chat request (requires roles/run.invoker)"
  value       = <<-EOT
    curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
      -H "Content-Type: application/json" \
      -d '{"message":"List my Cloud Run services"}' \
      ${google_cloud_run_v2_service.ops_agent.uri}/chat
  EOT
}

output "destroy_reminder" {
  description = "Cost habit: destroy idle Cloud Run when you are done demos for the day"
  value       = "When idle: cd terraform && terraform destroy. Images in Artifact Registry can stay (cheap) or be deleted separately."
}
