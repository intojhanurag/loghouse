output "connect_kubectl" {
  value = "gcloud container clusters get-credentials ${google_container_cluster.loghouse.name} --zone ${google_container_cluster.loghouse.location} --project ${var.project_id}"
}

output "image_registry" {
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.images.repository_id}"
}

output "cold_bucket" {
  value = google_storage_bucket.cold.name
}

output "github_workload_identity_provider" {
  value = google_iam_workload_identity_pool_provider.github.name
}

output "github_service_account" {
  value = google_service_account.github_ci.email
}
