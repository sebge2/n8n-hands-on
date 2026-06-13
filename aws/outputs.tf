output "public_ip" {
  value = aws_instance.n8n.public_ip
}

output "ssh_command" {
  value     = "ssh -i ${var.private_key_path} ${var.ssh_user}@${aws_instance.n8n.public_ip}"
}

output "ses_access_key_id" {
  value     = aws_iam_access_key.ses_key.id
  sensitive = true
}

output "ses_secret_access_key" {
  value     = aws_iam_access_key.ses_key.secret
  sensitive = true
}

output "ses_txt_record_name" {
  value = "_amazonses.n8n.sgerard.be"
}

output "ses_txt_record_value" {
  value = aws_ses_domain_identity.n8n_ses.verification_token
}

output "ses_dkim_cname_records" {
  value = [
    for token in aws_ses_domain_dkim.n8n_dkim.dkim_tokens : {
      name  = "${token}._domainkey.${var.main_domain_name}"
      value = "${token}.dkim.amazonses.com"
    }
  ]
}
