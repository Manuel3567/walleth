resource "google_storage_bucket" "frontend_bucket" {
  name          = var.frontend_bucket
  location      = var.frontend_bucket_location
  force_destroy = true
  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}

# Make bucket public
resource "google_storage_bucket_iam_member" "member" {
  bucket = google_storage_bucket.frontend_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

resource "google_compute_backend_bucket" "frontend_backend" {
  name        = "frontend-backend"
  bucket_name = google_storage_bucket.frontend_bucket.name

  # TODO: Flip cdn once stable
  enable_cdn = false
  #enable_cdn = true
}
resource "google_compute_global_address" "frontend_load_balancer_ip" {
  name = "frontend-load-balancer"
}
resource "google_compute_url_map" "frontend_url_map" {
  name = "frontend-url-map"

  default_service = google_compute_backend_bucket.frontend_backend.id
  host_rule {
    hosts        = [var.app_domain]
    path_matcher = "main"
  }
  path_matcher {
    name            = "main"
    default_service = google_compute_backend_bucket.frontend_backend.id

    path_rule {
      paths = ["/api/*"]
      url_redirect {
        strip_query   = false
        host_redirect = "httpbin.org"
        path_redirect = "/anything"
      }
    }
  }
}

resource "google_compute_global_forwarding_rule" "frontend_forwarding_rule" {
  name = "frontend-forwarding-rule"
  #target     = google_compute_backend_service.frontend_backend_service.self_link
  target     = google_compute_target_http_proxy.frontend_http_proxy.id
  ip_address = google_compute_global_address.frontend_load_balancer_ip.address
  port_range = "80"
}

resource "google_dns_record_set" "frontend_dns" {
  name         = "${var.app_domain}."
  type         = "A"
  ttl          = 300
  managed_zone = "app"
  rrdatas      = [google_compute_global_address.frontend_load_balancer_ip.address]
}

resource "google_compute_global_forwarding_rule" "frontend_https_forwarding_rule" {
  name = "frontend-https-forwarding-rule"
  target     = google_compute_target_https_proxy.frontend_https_proxy.id
  port_range = "443"
  ip_address = google_compute_global_address.frontend_load_balancer_ip.address
}

resource "google_compute_managed_ssl_certificate" "frontend_ssl_cert" {
  name    = "frontend-ssl-cert"
  project = var.gcp_project_id
  managed {
    domains = ["${var.app_domain}."]
  }
}

resource "google_compute_target_https_proxy" "frontend_https_proxy" {
  name = "frontend-https-proxy"
  ssl_certificates = [
    google_compute_managed_ssl_certificate.frontend_ssl_cert.self_link,
  ]
  url_map = google_compute_url_map.frontend_url_map.id
}

resource "google_compute_target_http_proxy" "frontend_http_proxy" {
  name    = "frontend-http-proxy"
  url_map = google_compute_url_map.frontend_url_map.id
}

output "load_balancer_ip" {
  value = google_compute_global_forwarding_rule.frontend_forwarding_rule.ip_address
}
