output "public_ip" {
  value = aws_instance.n8n.public_ip
}

output "ssh_command" {
  value     = "ssh -i ${var.private_key_path} ${var.ssh_user}@${aws_instance.n8n.public_ip}"
}
