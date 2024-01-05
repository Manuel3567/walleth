terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "1.1.1"
    }
    google = {
      source  = "hashicorp/google"
      version = "5.10.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.0"
    }
  }
}

provider "auth0" {}
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  zone    = var.gcp_default_zone
}

terraform {
  backend "gcs" {}
}

# used to access the project number
data "google_project" "project" {
}
