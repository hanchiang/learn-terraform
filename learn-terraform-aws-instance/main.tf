# The terraform {} block contains Terraform settings, including the required
# providers Terraform will use to provision your infrastructure.
# https://www.terraform.io/language/providers/requirements
terraform {
  # Terraform installs providers from the Terraform Registry by default.
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # The version attribute is optional, but we recommend using it to constrain the provider version
      # so that Terraform does not install a version of the provider that does not work with your configuration. 
      # The ~> operator is a convenient shorthand for allowing only patch releases within a specific minor release
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

# The provider block configures the specified provider, in this case aws.
# A provider is a plugin that Terraform uses to create and manage your resources.
provider "aws" {
  region = "us-east-1"
}

# Use resource blocks to define components of your infrastructure. A resource might be a physical or virtual component
# such as an EC2 instance, or it can be a logical resource such as a Heroku application.
# <resource-type> <resource-name>
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_ipv4_cidr
  enable_dns_hostnames = true

  tags = {
    Name   = var.tag_name
    System = var.tag_name
  }

}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name   = var.tag_name
    System = var.tag_name
  }
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name   = "public 1a"
    System = var.tag_name
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name   = "public 1b"
    System = var.tag_name
  }
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name   = "private 1a"
    System = var.tag_name
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name   = "public 1b"
    System = var.tag_name
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name   = "public"
    System = var.tag_name
  }
}

resource "aws_route" "public" {
  route_table_id = aws_route_table.public.id

  destination_cidr_block = var.all_ipv4_cidr
  gateway_id             = aws_internet_gateway.gateway.id
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}


resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = {
    Name   = "public"
    System = var.tag_name
  }
}

resource "aws_network_acl" "private" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = {
    Name   = "private"
    System = var.tag_name
  }
}

resource "aws_network_acl_rule" "allow_public_incoming_http" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.all_ipv4_cidr
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "allow_public_incoming_https" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 101
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.all_ipv4_cidr
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "allow_public_incoming_ssh" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 102
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.my_home_ipv4_cidr
  from_port      = 22
  to_port        = 22
}

resource "aws_network_acl_rule" "allow_public_incoming_tcp_ephemeral" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 103
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.all_ipv4_cidr
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "allow_public_outgoing_http" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.all_ipv4_cidr
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "allow_public_outgoing_https" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 101
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.all_ipv4_cidr
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "allow_public_outgoing_tcp_ephemeral" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 102
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.all_ipv4_cidr
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "allow_private_incoming_http" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpc_ipv4_cidr
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "allow_private_incoming_https" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 101
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpc_ipv4_cidr
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "allow_private_outgoing_tcp_ephemeral" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpc_ipv4_cidr
  from_port      = 1024
  to_port        = 65535
}

resource "aws_security_group" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name   = "Public"
    System = var.tag_name
  }
}

resource "aws_security_group" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name   = "Private"
    System = var.tag_name
  }
}

resource "aws_security_group_rule" "public_incoming_http" {
  security_group_id = aws_security_group.public.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [var.all_ipv4_cidr]
}

resource "aws_security_group_rule" "public_incoming_https" {
  security_group_id = aws_security_group.public.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [var.all_ipv4_cidr]
}

resource "aws_security_group_rule" "public_incoming_ssh" {
  security_group_id = aws_security_group.public.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.my_home_ipv4_cidr]
}

resource "aws_security_group_rule" "public_outgoing_http" {
  security_group_id = aws_security_group.public.id
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [var.all_ipv4_cidr]
}

resource "aws_security_group_rule" "public_outgoing_https" {
  security_group_id = aws_security_group.public.id
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [var.all_ipv4_cidr]
}

resource "aws_security_group_rule" "private_incoming_http" {
  security_group_id = aws_security_group.private.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_ipv4_cidr]
}

resource "aws_security_group_rule" "private_incoming_https" {
  security_group_id = aws_security_group.private.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_ipv4_cidr]
}

resource "aws_security_group_rule" "private_outgoing_tcp" {
  security_group_id = aws_security_group.private.id
  type              = "egress"
  from_port         = 1024
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_ipv4_cidr]
}

resource "aws_instance" "app_server" {
  ami                    = "ami-0022f774911c1d690"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.public.id]

  tags = {
    Name   = var.tag_name
    System = var.tag_name
  }
}
