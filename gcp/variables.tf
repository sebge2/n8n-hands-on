variable "tags" {
  description = "Tags to add on resources"
  default     = ["n8n-server"]
  type = list(string)
}

variable "gcp_region" {
  description = "The name of the GCP region"
  default     = "europe-west1"
  type        = string
}

variable "gcp_project_id" {
  description = "GCP project id"
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance type of nodes"
  default     = "e2-medium"
}

variable "domain_name" {
  type        = string
  description = "Fully-qualified domain name for the n8n instance and the AWS-managed hosted zone (e.g. n8n.example.com). Delegate this name from the parent zone via NS records."
}

variable "postgresql_user" {
  type = string
  default = "admin"
}

variable "postgresql_password" {
  type = string
  default = "4jCS4yX[FFu:jGf3P9Q>TqS~"
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
