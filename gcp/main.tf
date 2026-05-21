provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

resource "tls_private_key" "n8n-keypair" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Save the private key to a local file
resource "local_file" "private_key" {
  content  = tls_private_key.n8n-keypair.private_key_pem
  filename        = pathexpand(var.private_key_path)
  file_permission = "0400"
}

# Save the public key to a local file
resource "local_file" "public_key" {
  content  = tls_private_key.n8n-keypair.public_key_pem
  filename        = pathexpand(var.public_key_path)
  file_permission = "0400"
}

locals {
  env_rendered = templatefile("${path.module}/templates/env.tmpl", {
    POSTGRES_USER                     = var.postgresql_user
    POSTGRES_PASSWORD                 = var.postgresql_password

    N8N_RUNNERS_AUTH_TOKEN            = var.n8n_user_auth_token
    N8N_ENCRYPTION_KEY                = var.n8n_encryption_key

    DOMAIN_NAME                       = var.domain_name

    OLLAMA_API_KEY                    = var.ollama_api_key

    OS_USER                           = var.ssh_user
  })

  startup_script = templatefile("${path.module}/templates/user_data.sh.tmpl", {
    env_file = replace(local.env_rendered, "$", "\\$")
  })
}

resource "google_compute_instance" "n8n" {
  name         = "n8n-server"
  machine_type = var.instance_type
  zone         = "europe-west1-b"
  metadata_startup_script = local.startup_script
  tags = var.tags

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 50 # Go
      type  = "pd-ssd" # Plus rapide que pd-standard
    }
  }

  network_interface {
    network = "default"
    access_config {
      # Ce bloc donne une IP publique éphémère
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${tls_private_key.n8n-keypair.public_key_openssh}"
  }

  provisioner "file" {
    source      = "${path.module}/../n8n-data"
    destination = "/home/${var.ssh_user}/"

    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = tls_private_key.n8n-keypair.private_key_pem
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }
}

resource "google_compute_firewall" "n8n_firewall" {
  name    = "allow-n8n-and-web"
  network = "default"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = var.tags

  allow {
    protocol = "tcp"
    ports    = ["22", "5678"]
  }
}