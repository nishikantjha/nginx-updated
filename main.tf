provider "google" {
  version = "4.30.0"
  credentials = file("tf-service-account.json")
  project = var.project
  region  = var.region
  zone    = "${var.region}-c"
  
}

resource "google_compute_firewall" "firewall" {
  name    = "fw-externalssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"] 
  target_tags   = ["externalssh"]
}

resource "google_compute_firewall" "webserver-fw" {
  name    = "http-webserver"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80","443"]
  }

  source_ranges = ["0.0.0.0/0"] 
  target_tags   = ["webserver"]
}

#Public IP
resource "google_compute_address" "static" {
  name = "vm-public-address"
  project = var.project
  region = var.region
  depends_on = [ google_compute_firewall.firewall ]
}

#Cloud DNS Zone
resource "google_dns_managed_zone" "prod" {
  project = var.project
  name     = "managed-zone-nginx"
  dns_name = "${var.domain}."
  description = "Managed DNS zone"
}

output "domain_name" {
  value = var.domain
}

#devopstesting.tk
resource "google_dns_record_set" "A" {
  name = "${google_dns_managed_zone.prod.dns_name}"
  type = "A"
  ttl  = 300
  managed_zone = google_dns_managed_zone.prod.name
  rrdatas = [google_compute_instance.prod.network_interface[0].access_config[0].nat_ip]
}

resource "google_dns_record_set" "www" {
  name = "www.${google_dns_managed_zone.prod.dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = google_dns_managed_zone.prod.name

  rrdatas = [google_compute_instance.prod.network_interface[0].access_config[0].nat_ip]
}


#Ubuntu 20.04
data "google_compute_image" "debian" {
  family  = "ubuntu-2004-lts"
  project = "ubuntu-os-cloud"
}

resource "google_compute_instance" "prod" {
  name         = "nginx-ubuntu"
  machine_type = "f1-micro"
  zone         = "${var.region}-c"
  hostname     = var.domain
  tags         = ["externalssh","webserver","http-server","https-server"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian.self_link
    }
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = google_compute_address.static.address
    }
  }

  depends_on = [ google_compute_firewall.firewall, google_compute_firewall.webserver-fw ]

  service_account {
    email  = var.email
    scopes = ["compute-ro"]
  }
  
  metadata_startup_script = data.template_file.nginx.rendered
  #SSH Connection
  metadata = {
    ssh-keys = "${var.user}:${file(var.publickeypath)}"
  }
}

output "ssh" {
  value = "ssh ${var.user}@${google_compute_address.static.address}"
}

#Startup Script
data "template_file" "nginx" {
  template = "${file("${path.module}/template/install_nginx.tpl")}"

  vars = {
    ufw_allow_nginx = "Nginx HTTP"
  }
}

output "URL" {

  value = "https://${var.domain} and https://www.${var.domain}"
  
}





