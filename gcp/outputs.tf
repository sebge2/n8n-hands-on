output "public_ip" {
  value = google_compute_instance.n8n.network_interface[0].access_config[0].nat_ip
}

output "ssh_command" {
  value = "ssh -i ${var.private_key_path} ${var.ssh_user}@${google_compute_instance.n8n.network_interface[0].access_config[0].nat_ip}"
}