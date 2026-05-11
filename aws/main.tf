provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = var.tags
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.main.id
  tags   = var.tags
}

resource "aws_eip" "eip" {
  depends_on = [aws_internet_gateway.gateway]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = element(aws_subnet.public_subnet.*.id, 0)
  depends_on    = [aws_internet_gateway.gateway]
  tags          = var.tags
}

resource "aws_subnet" "public_subnet" {
  cidr_block        = var.my_ip_cidr
  vpc_id            = aws_vpc.main.id
  availability_zone = "${var.aws_region}${var.aws_main_availability_zone}"
  tags              = var.tags
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = var.tags
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gateway.id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id
}

resource "aws_vpc_dhcp_options" "local-domain" {
  domain_name          = var.local_domain
  domain_name_servers  = ["AmazonProvidedDNS"]

  tags = var.tags
}

resource "aws_vpc_dhcp_options_association" "local_dns_resolver" {
  vpc_id          = aws_vpc.main.id
  dhcp_options_id = aws_vpc_dhcp_options.local-domain.id
}

resource "aws_security_group" "ssh" {
  vpc_id      = aws_vpc.main.id
  name        = "${var.default_resource_name}-ssh"
  description = "Security group that allows SSH connections"

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }

  tags = var.tags
}

# Generate an RSA private key
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

resource "aws_key_pair" "n8n_key" {
  key_name   = var.key_name
  public_key = tls_private_key.n8n-keypair.public_key_openssh
}

resource "aws_security_group" "n8n_sg" {
  name = "n8n-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5678
    to_port     = 5678
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

locals {
  env_rendered = templatefile("${path.module}/templates/env.tmpl", {
    POSTGRES_USER                  = var.postgresql_user
    POSTGRES_PASSWORD              = var.postgresql_password
    N8N_INSTANCE_OWNER_EMAIL       = var.n8n_user_email
    N8N_INSTANCE_OWNER_FIRST_NAME  = var.n8n_user_firstname
    N8N_INSTANCE_OWNER_LAST_NAME   = var.n8n_user_lastname
    N8N_INSTANCE_OWNER_PASSWORD_HASH   = var.n8n_user_password
  })

  user_data_rendered = templatefile("${path.module}/templates/user_data.sh.tmpl", {
    env_file = replace(local.env_rendered, "$", "\\$")
  })
}

resource "aws_instance" "n8n" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.n8n_key.key_name
  vpc_security_group_ids = [aws_security_group.n8n_sg.id]
  subnet_id = aws_subnet.public_subnet.id
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 30
    delete_on_termination = true
  }

  user_data = local.user_data_rendered
  tags = {
    Name = "n8n-server"
  }
}

resource "aws_route53_zone" "main" {
  name = var.domain_name
  tags = var.tags
}

resource "aws_route53_record" "n8n_dns" {
  count   = var.create_dns_record ? 1 : 0
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 300
  records = [aws_instance.n8n.public_ip]
}