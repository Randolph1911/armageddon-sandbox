# Authentication
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.28.0"
    }
  }
}

provider "google" {
  credentials = "armageddon-sandbox-8221597e6835.json"
  project     = "armageddon-sandbox"
  region      = "us-east4"
  zone        = "us-east4-a"
}

#Virtual Private Cloud
resource "google_compute_network" "vpc-forward-base" {
  name                    = "vpc-forward-base"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "us-east4a-subnet" {
  name                     = "us-east4a-subnet"
  network                  = google_compute_network.vpc-forward-base.self_link
  ip_cidr_range            = "10.153.1.0/24"
  region                   = "us-east4"
  private_ip_google_access = true
}

resource "google_compute_firewall" "allow-icmp" {
  name    = "icmp-test-firewall"
  network = google_compute_network.vpc-forward-base.self_link

  allow {
    protocol = "icmp"
  }
  source_ranges = ["0.0.0.0/0"]
  priority      = 600
}

resource "google_compute_firewall" "http" {
  name    = "allow-http"
  network = google_compute_network.vpc-forward-base.self_link

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  source_ranges = ["0.0.0.0/0"]
  priority      = 100
}

resource "google_compute_instance" "vm-forward-base" {
  name         = "vm-forward-base"
  machine_type = "e2-medium"
  zone         = "us-east4-a"

  metadata_startup_script = file("forward-base.sh")

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network    = google_compute_network.vpc-forward-base.self_link
    subnetwork = google_compute_subnetwork.us-east4a-subnet.self_link

    access_config {
      // Ephemeral IP
    }
  }
}

#Outputs

output "instance_public_ip" {
  description = "The public IP address of the web server"
  value       = google_compute_instance.vm-forward-base.network_interface[0].access_config[0].nat_ip
}

output "vpc-forward-base" {
  description = "The ID of the VPC"
  value       = google_compute_network.vpc-forward-base.self_link
}

output "instance_subnet" {
  description = "The subnet of the VM instance"
  value       = google_compute_instance.vm-forward-base.network_interface[0].subnetwork
}

output "instance_internal_ip" {
  description = "The Internal IP address of the VM instance"
  value       = google_compute_instance.vm-forward-base.network_interface[0].network_ip
}
