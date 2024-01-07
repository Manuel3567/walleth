# Admin service
resource "google_service_account" "admin_service" {
  account_id   = var.admin_service_account_name
  display_name = "Admin Service Account"
}

resource "google_project_iam_member" "admin_service_cloud_storage_permissions" {
  project = var.gcp_project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.admin_service.email}"
}

resource "google_service_account_iam_member" "admin_service_kubernetes_trust" {
  service_account_id = google_service_account.admin_service.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.gcp_project_id}.svc.id.goog[${var.kubernetes_namespace}/${var.admin_service_account_name}]"
}

# Aggregation service
resource "google_service_account" "aggregation_service" {
  account_id   = var.aggregation_service_account_name
  display_name = "Aggregation Service Account"
}

resource "google_project_iam_member" "aggregation_service_cloud_storage_permissions" {
  project = var.gcp_project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.aggregation_service.email}"
}

resource "google_service_account_iam_member" "aggregation_service_kubernetes_trust" {
  service_account_id = google_service_account.aggregation_service.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.gcp_project_id}.svc.id.goog[${var.kubernetes_namespace}/${var.aggregation_service_account_name}]"
}

# Data service
resource "google_service_account" "data_service" {
  account_id   = var.data_service_account_name
  display_name = "Data Service Account"
}

resource "google_project_iam_member" "data_service_cloud_storage_permissions" {
  project = var.gcp_project_id
  role    = "roles/datastore.owner"
  member  = "serviceAccount:${google_service_account.data_service.email}"
}

resource "google_service_account_iam_member" "data_service_kubernetes_trust" {
  service_account_id = google_service_account.data_service.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.gcp_project_id}.svc.id.goog[${var.kubernetes_namespace}/${var.data_service_account_name}]"
}

# Ethereum service
resource "google_service_account" "ethereum_service" {
  account_id   = var.ethereum_service_account_name
  display_name = "Ethereum Service Account"
}

# resource "google_project_iam_member" "ethereum_service_cloud_storage_permissions" {
#   project = var.gcp_project_id
#   role    = "roles/storage.admin"
#   member  = "serviceAccount:${google_service_account.ethereum_service.email}"
# }

resource "google_service_account_iam_member" "ethereum_service_kubernetes_trust" {
  service_account_id = google_service_account.ethereum_service.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.gcp_project_id}.svc.id.goog[${var.kubernetes_namespace}/${var.ethereum_service_account_name}]"
}


# Refresh service
resource "google_service_account" "refresh_service" {
  account_id   = var.refresh_service_account_name
  display_name = "Refresh Service Account"
}

resource "google_project_iam_member" "refresh_service_cloud_storage_permissions" {
  project = var.gcp_project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.refresh_service.email}"
}

resource "google_service_account_iam_member" "refresh_service_kubernetes_trust" {
  service_account_id = google_service_account.refresh_service.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.gcp_project_id}.svc.id.goog[${var.kubernetes_namespace}/${var.refresh_service_account_name}]"
}
