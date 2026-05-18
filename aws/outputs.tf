output "n8n_instance_public_ip" {
  value = aws_instance.n8n.public_ip
}

output "public_ip" {
  value = aws_instance.n8n.public_ip
}

output "ssh_command" {
  value     = "ssh -i ${var.private_key_path} ubuntu@${aws_instance.n8n.public_ip}"
}
