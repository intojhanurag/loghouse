resource "random_password" "clickhouse" {
  length  = 24
  special = false
}

locals {
  secrets = {
    "clickhouse-password" = random_password.clickhouse.result
    "gcs-hmac-access-id"  = google_storage_hmac_key.clickhouse.access_id
    "gcs-hmac-secret"     = google_storage_hmac_key.clickhouse.secret
  }
}

resource "google_secret_manager_secret" "this" {
  for_each  = local.secrets
  secret_id = each.key

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret_version" "this" {
  for_each    = local.secrets
  secret      = google_secret_manager_secret.this[each.key].id
  secret_data = each.value
}
