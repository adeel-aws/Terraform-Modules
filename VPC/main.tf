locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# -------------------
# VPC
# -------------------
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

# -------------------
# SUBNETS
# -------------------
resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone      = var.azs[count.index % length(var.azs)]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-public-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id           = aws_vpc.this.id
  cidr_block       = var.private_subnets[count.index]
  availability_zone = var.azs[count.index % length(var.azs)]

  tags = {
    Name = "${local.name_prefix}-private-${count.index + 1}"
  }
}

# -------------------
# IGW
# -------------------
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

# -------------------
# PUBLIC ROUTE TABLE
# -------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${local.name_prefix}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnets)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# -------------------
# NAT (optional)
# -------------------
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway && var.create_eip ? 1 : 0

  tags = {
    Name = "${local.name_prefix}-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  count = var.enable_nat_gateway ? 1 : 0

  subnet_id     = aws_subnet.public[0].id
  allocation_id = var.create_eip && length(aws_eip.nat) > 0 ? aws_eip.nat[0].id : null

  depends_on = [aws_internet_gateway.this]

  tags = {
    Name = "${local.name_prefix}-nat"
  }
}

# -------------------
# PRIVATE ROUTE TABLE
# -------------------
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  dynamic "route" {
    for_each = var.enable_nat_gateway && length(aws_nat_gateway.nat) > 0 ? aws_nat_gateway.nat : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = route.value.id
    }
  }

  tags = {
    Name = "${local.name_prefix}-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnets)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# -------------------
# ELB SG
# -------------------
resource "aws_security_group" "elb_sg" {
  count  = var.create_elb_sg ? 1 : 0
  vpc_id = aws_vpc.this.id

  dynamic "ingress" {
    for_each = var.elb_ingress_rules
    content {
      from_port = ingress.value.from_port
      to_port   = ingress.value.to_port
      protocol  = ingress.value.protocol

      cidr_blocks     = try(ingress.value.cidr_blocks, null)
      security_groups = try(ingress.value.security_groups, null)
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-elb-sg"
  }
}

# -------------------
# APP SG
# -------------------
resource "aws_security_group" "app_sg" {
  count  = var.create_app_sg ? 1 : 0
  vpc_id = aws_vpc.this.id

  dynamic "ingress" {
    for_each = var.app_ingress_rules
    content {
      from_port = ingress.value.from_port
      to_port   = ingress.value.to_port
      protocol  = ingress.value.protocol

      cidr_blocks     = try(ingress.value.cidr_blocks, null)
      security_groups = try(ingress.value.security_groups, null)
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-app-sg"
  }
}

# -------------------
# DB SG
# -------------------
resource "aws_security_group" "db_sg" {
  count  = var.create_db_sg ? 1 : 0
  vpc_id = aws_vpc.this.id

  dynamic "ingress" {
    for_each = var.db_ingress_rules
    content {
      from_port = ingress.value.from_port
      to_port   = ingress.value.to_port
      protocol  = ingress.value.protocol

      cidr_blocks     = try(ingress.value.cidr_blocks, null)
      security_groups = try(ingress.value.security_groups, null)
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-db-sg"
  }
}