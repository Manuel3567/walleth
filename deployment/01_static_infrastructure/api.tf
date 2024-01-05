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
