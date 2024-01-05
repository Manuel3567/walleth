resource "google_artifact_registry_repository" "docker" {
  format        = "DOCKER"
  location      = var.gcp_region
  repository_id = var.docker_repository_name
  description   = "Docker repository"

  docker_config {
    # TODO: flip once stable releases happen
    immutable_tags = false
  }
}

