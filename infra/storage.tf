resource "google_artifact_registry_repository" "images" {
  repository_id = "loghouse"
  location      = var.region
  format        = "DOCKER"
  depends_on    = [google_project_service.apis]
}

resource "google_storage_bucket" "cold" {
  name                        = "${var.project_id}-clickhouse-cold"
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = true
}

resource "google_service_account" "clickhouse_gcs" {
  account_id   = "clickhouse-gcs"
  display_name = "ClickHouse access to the cold bucket"
}

resource "google_storage_bucket_iam_member" "clickhouse_gcs" {
  bucket = google_storage_bucket.cold.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.clickhouse_gcs.email}"
}

resource "google_storage_hmac_key" "clickhouse" {
  service_account_email = google_service_account.clickhouse_gcs.email
}
