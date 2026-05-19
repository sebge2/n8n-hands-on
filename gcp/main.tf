provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

locals {
  env_rendered = templatefile("${path.module}/templates/env.tmpl", {
    POSTGRES_USER                     = var.postgresql_user
    POSTGRES_PASSWORD                 = var.postgresql_password

    N8N_RUNNERS_AUTH_TOKEN            = var.n8n_user_auth_token
    N8N_ENCRYPTION_KEY                = var.n8n_encryption_key

    DOMAIN_NAME                       = var.domain_name

    OLLAMA_API_KEY                    = var.ollama_api_key
  })

  startup_script = templatefile("${path.module}/templates/user_data.sh.tmpl", {
    env_file = replace(local.env_rendered, "$", "\\$")
  })
}

resource "google_compute_instance" "n8n" {
  name         = "n8n-server"
  machine_type = var.instance_type
  zone         = "europe-west1-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 30 # 30 Go
    }
  }

  network_interface {
    network = "default"
    access_config {
      # Ce bloc donne une IP publique éphémère
    }
  }

  metadata_startup_script = local.startup_script

  tags = var.tags
}