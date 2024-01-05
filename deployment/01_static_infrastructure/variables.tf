variable "gcp_project_id" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "gcp_default_zone" {
  type = string
}

variable "api_url" {
  type = string
}

variable "app_url" {
  type = string
}

variable "app_domain" {
  type = string
}

variable "api_domain" {
  type = string
}
variable "frontend_bucket" {
  type = string
}

variable "frontend_bucket_location" {
  type = string
}

variable "auth0_redirect_uri" {
  type = string
}

variable "docker_repository_name" {
  type = string
}

variable "kubernetes_namespace" {
  type = string
}

variable "admin_service_account_name" {
  type = string
}

variable "aggregation_service_account_name" {
  type = string
}

variable "data_service_account_name" {
  type = string
}

variable "ethereum_service_account_name" {
  type = string
}

variable "refresh_service_account_name" {
  type = string
}
