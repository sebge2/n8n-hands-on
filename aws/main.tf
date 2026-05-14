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

resource "aws_security_group" "alb_sg" {
  name = "alb_sg"
  vpc_id = aws_vpc.main.id

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
  env_rendered = templatefile("${path.module}/templates/env.tmpl", {
    POSTGRES_USER                     = var.postgresql_user
    POSTGRES_PASSWORD                 = var.postgresql_password
    N8N_INSTANCE_OWNER_EMAIL          = var.n8n_user_email
    N8N_INSTANCE_OWNER_FIRST_NAME     = var.n8n_user_firstname
    N8N_INSTANCE_OWNER_LAST_NAME      = var.n8n_user_lastname
    N8N_INSTANCE_OWNER_PASSWORD_HASH  = var.n8n_user_password
    N8N_RUNNERS_AUTH_TOKEN            = var.n8n_user_auth_token
    DOMAIN_NAME                       = var.domain_name
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
  subnet_id = aws_subnet.main_public_subnet.id
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


# resource "aws_acm_certificate" "cert" {
#   domain_name       = var.domain_name
#   validation_method = "DNS"
# }
#
# resource "aws_acm_certificate_validation" "cert" {
#   certificate_arn         = aws_acm_certificate.cert.arn
#   validation_record_fqdns = [for record in aws_route53_record.n8n_dns : record.fqdn]
# }
#
# resource "aws_lb_target_group" "main" {
#   name     = "n8n-target-group"
#   port     = 5678
#   protocol = "HTTP"
#   vpc_id   = aws_vpc.main.id
#
#   health_check {
#     path                = "/healthz" # n8n's health check endpoint
#     port                = 5678
#     healthy_threshold   = 2
#     unhealthy_threshold = 10
#   }
# }
#
# resource "aws_lb_target_group_attachment" "n8n_attach" {
#   target_group_arn = aws_lb_target_group.main.arn
#   target_id        = aws_instance.n8n.id
#   port             = 5678
# }
#
# resource "aws_lb" "n8n_alb" {
#   name               = "n8n-alb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.n8n_sg.id]
#   subnets            = [aws_subnet.main_public_subnet.id, aws_subnet.secondary_public_subnet.id]
# }
#
# resource "aws_lb_listener" "https" {
#   load_balancer_arn = aws_lb.n8n_alb.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = aws_acm_certificate.cert.arn
#
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.main.arn
#   }
# }
#
# resource "aws_security_group_rule" "allow_alb_to_ec2" {
#   type                     = "ingress"
#   from_port                = 5678
#   to_port                  = 5678
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.n8n_sg.id
#   source_security_group_id = aws_security_group.alb_sg.id
# }


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
  #records = [ aws_lb.n8n_alb.dns_name]
  records = [aws_instance.n8n.public_ip]
}