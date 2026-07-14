# Who may *call* the Cloud Run URL (caller identity).
# Separate from sa-ops-agent, which is the *runtime* identity inside the container.
# Do NOT add member = "allUsers" — that would expose Gemini quota to the internet.

resource "google_cloud_run_v2_service_iam_member" "invokers" {
  for_each = toset(var.demo_invoker_members)

  project  = var.project_id
  location = google_cloud_run_v2_service.ops_agent.location
  name     = google_cloud_run_v2_service.ops_agent.name
  role     = "roles/run.invoker"
  member   = each.value
}
