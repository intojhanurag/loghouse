resource "google_container_cluster" "loghouse" {
  name     = "loghouse"
  location = local.zones[0]

  remove_default_node_pool = true
  initial_node_count       = 1
  deletion_protection      = false

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  depends_on = [google_project_service.apis]
}

resource "google_container_node_pool" "spot" {
  name           = "spot"
  cluster        = google_container_cluster.loghouse.name
  location       = google_container_cluster.loghouse.location
  node_locations = local.zones
  node_count     = 1

  node_config {
    spot         = true
    machine_type = "e2-standard-4"
    disk_size_gb = 50
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
}
