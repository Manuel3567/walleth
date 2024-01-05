resource "google_service_account" "cluster" {
  account_id   = "kubernetes"
  display_name = "Kubernetes Cluster Service Account"
}

# was created with terraform but subsecquently forgotten
#resource "google_kms_key_ring" "keyring" {
#  name     = "kubernetes_keyring"
#  location = var.gcp_region
#  # cannot be deleted
#  lifecycle {
#    prevent_destroy = true
#  }
#}
#
#resource "google_kms_crypto_key" "etcd_key" {
#  name            = "kubernetes"
#  key_ring        = google_kms_key_ring.keyring.id
#  rotation_period = "10368000s" # 120 days
#
#  # cannot be deleted with terraform, better to never delete
#  lifecycle {
#    prevent_destroy = true
#  }
#}

data "google_kms_key_ring" "keyring" {
  name     = "kubernetes_keyring"
  location = var.gcp_region
}

data "google_kms_crypto_key" "etcd_key" {
  name     = "kubernetes"
  key_ring = data.google_kms_key_ring.keyring.id
}


resource "google_project_iam_member" "artifactory_pull_permission" {
  project = var.gcp_project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.cluster.email}"
}


# note that the the default GKE service role does not get access to the KMS key automatically
resource "google_kms_crypto_key_iam_binding" "etcd_key_access" {
  crypto_key_id = data.google_kms_crypto_key.etcd_key.id
  members = [
    "serviceAccount:${google_service_account.cluster.email}",
    "serviceAccount:service-${data.google_project.project.number}@container-engine-robot.iam.gserviceaccount.com", # default gke service account
  ]
  role = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
}


resource "google_container_cluster" "primary" {
  depends_on          = [google_kms_crypto_key_iam_binding.etcd_key_access]
  name                = "cluster"
  location            = var.gcp_region
  deletion_protection = false
  networking_mode     = "VPC_NATIVE"
  # gateway api replaces ingress long term
  gateway_api_config {
    channel = "CHANNEL_STANDARD"
  }


  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  initial_node_count       = 1
  remove_default_node_pool = true
  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }
  database_encryption {
    state    = "ENCRYPTED"
    key_name = data.google_kms_crypto_key.etcd_key.id
  }
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name     = "kubernetes-node-pool"
  location = var.gcp_region
  cluster  = google_container_cluster.primary.name
  autoscaling {
    total_min_node_count = 0
    total_max_node_count = 3
  }

  node_config {
    machine_type = "e2-medium"
    #spot = true

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.cluster.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    tags = ["application", "portfolioeth"]

  }
}
