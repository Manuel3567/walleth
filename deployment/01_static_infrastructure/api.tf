# state is managed in gcp bucket and encrypted at rest
# for increased security, consider storing the password in a security store
resource "random_password" "api_admin_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
output "api_admin_password" {
  sensitive = true
  value     = random_password.api_admin_password.result
}

resource "random_password" "api_viewer_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
output "api_viewer_password" {
  sensitive = true
  value     = random_password.api_admin_password.result
}

resource "google_compute_global_address" "api_load_balancer_ip" {
  name = "api-load-balancer"
}
resource "google_dns_record_set" "api_dns" {
  name         = "${var.api_domain}."
  type         = "A"
  ttl          = 300
  managed_zone = "app"
  rrdatas      = [google_compute_global_address.api_load_balancer_ip.address]
}
resource "google_compute_managed_ssl_certificate" "api_tls_cert" {
  name    = "api-tls-certificate"
  project = var.gcp_project_id
  managed {
    domains = ["${var.api_domain}."]
  }
}
output "api_load_balancer_ip" {
  value = google_compute_global_address.api_load_balancer_ip.address
}
