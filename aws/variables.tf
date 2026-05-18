variable "tags" {
  description = "Tags to add on resources"
  default     = {
    Name : "n8n-hands-on"
  }
  type = map(string)
}

variable "aws_region" {
  description = "The name of the AWS region"
  default     = "eu-central-1"
  type        = string
}

variable "aws_main_availability_zone" {
  description = "The name of the main AWS region"
  default     = "a"
  type        = string
}

variable "aws_secondary_availability_zone" {
  description = "The name of the secondary AWS region"
  default     = "b"
  type        = string
}

variable "aws_zone_id" {
  default = "Zone ID in route 53"
  type = string
}

variable "main_ip_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "secondary_ip_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "instance_type" {
  description = "The EC2 instance type of nodes"
  default     = "t3.medium"
}

variable "public_key_path" {
  type    = string
  default = "~/.ssh/n8n.pem"
}

variable "private_key_path" {
  type    = string
  default = "~/.ssh/n8n.key"
}

variable "local_domain" {
  description = "Local DNS domain"
  type    = string
  default = "n8n.local"
}

variable "key_name" {
  type        = string
  description = "SSH key pair name"
}

variable "domain_name" {
  type        = string
  description = "Fully-qualified domain name for the n8n instance and the AWS-managed hosted zone (e.g. n8n.example.com). Delegate this name from the parent zone via NS records."
}

variable "create_dns_record" {
  default = true
}

variable "postgresql_user" {
  type = string
  default = "admin"
}

variable "postgresql_password" {
  type = string
}

variable "n8n_user_auth_token" {
  type = string
  description = "Token to authenticate the runner"
  default = "UtBmyq60zzq6MlUvSRXEbRuky"
}

variable "n8n_encryption_key" {
  type = string
  description = "Key used to encrypt date"
  default = "hQU7nbNIz6p1YlBdQT925RwP"
}

variable "ollama_api_key" {
  type = string
  description = "Ollama API key"
  default = "1c2380eaf2724f8fab4d1b977401ea94.IcevmedYWDohSYRkoWbawUhA"
}
