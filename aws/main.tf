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
  subnet_id     = aws_subnet.main_public_subnet.id
  depends_on    = [aws_internet_gateway.gateway]
  tags          = var.tags
}

resource "aws_subnet" "main_public_subnet" {
  cidr_block        = var.main_ip_cidr
  vpc_id            = aws_vpc.main.id
  availability_zone = "${var.aws_region}${var.aws_main_availability_zone}"
  tags              = var.tags
}

resource "aws_subnet" "secondary_public_subnet" {
  cidr_block        = var.secondary_ip_cidr
  vpc_id            = aws_vpc.main.id
  availability_zone = "${var.aws_region}${var.aws_secondary_availability_zone}"
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

resource "aws_route_table_association" "main_public" {
  subnet_id      = aws_subnet.main_public_subnet.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "secondary_public" {
  subnet_id      = aws_subnet.secondary_public_subnet.id
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
  tags = var.tags
}

resource "aws_security_group" "n8n_sg" {
  name = "n8n-sg"
  vpc_id = aws_vpc.main.id
  tags = var.tags

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
  env_rendered = templatefile("${path.module}/../templates/env.tmpl", {
    POSTGRES_USER                     = var.postgresql_user
    POSTGRES_PASSWORD                 = var.postgresql_password

    N8N_RUNNERS_AUTH_TOKEN            = var.n8n_user_auth_token
    N8N_ENCRYPTION_KEY                = var.n8n_encryption_key

    DOMAIN_NAME                       = var.domain_name

    OLLAMA_API_KEY                    = var.ollama_api_key

    OS_USER                           = var.ssh_user
  })

  user_data_rendered = templatefile("${path.module}/../templates/user_data.sh.tmpl", {
    env_file     = replace(local.env_rendered, "$", "\\$")

    nginx_config = local.nginx_rendered
    ssh_user     = var.ssh_user
  })

  nginx_rendered = templatefile("${path.module}/../templates/n8n.conf.tmpl", {
    DOMAIN_NAME                       = var.domain_name
  })
}

resource "aws_instance" "n8n" {
  ami                           = data.aws_ami.ubuntu.id
  instance_type                 = var.instance_type
  key_name                      = aws_key_pair.n8n_key.key_name
  vpc_security_group_ids        = [aws_security_group.n8n_sg.id]
  subnet_id                     = aws_subnet.main_public_subnet.id
  associate_public_ip_address   = true
  user_data                     = local.user_data_rendered
  tags                          = var.tags

  root_block_device {
    volume_size           = 30
    delete_on_termination = true
  }

  provisioner "file" {
    source      = "${path.module}/../n8n-data"
    destination = "/home/${var.ssh_user}/"

    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = tls_private_key.n8n-keypair.private_key_pem
      host        = self.public_ip
    }
  }
}


# Commented because the AWS DNS server changes every time the instance is re-created
# resource "aws_route53_zone" "main" {
#   name = var.domain_name
#   tags = var.tags
# }


resource "aws_route53_record" "n8n_dns" {
  count   = var.create_dns_record ? 1 : 0
  zone_id = var.aws_zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 300
  records = [aws_instance.n8n.public_ip]
}


resource "aws_ses_domain_identity" "n8n_ses" {
  domain = var.main_domain_name
}

resource "aws_ses_domain_dkim" "n8n_dkim" {
  domain = aws_ses_domain_identity.n8n_ses.domain
}

resource "aws_iam_user" "ses_user" {
  name = "n8n-ses-sender"
}

resource "aws_iam_user_policy" "ses_policy" {
  name = "ses-send-policy"
  user = aws_iam_user.ses_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_access_key" "ses_key" {
  user = aws_iam_user.ses_user.name
}