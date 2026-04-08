# -------------------
# VPC
# -------------------
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

# -------------------
# SUBNETS (Multi-AZ)
# -------------------
resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.azs[count.index % length(var.azs)]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.vpc_name}-public-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.azs[count.index % length(var.azs)]

  tags = {
    Name = "${var.vpc_name}-private-${count.index + 1}"
  }
}

# -------------------
# INTERNET GATEWAY + PUBLIC ROUTE TABLE
# -------------------
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.vpc_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnets)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# -------------------
# NAT (Optional)
# -------------------
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway && var.create_eip ? 1 : 0

  # no vpc argument
  tags = {
    Name = "${var.vpc_name}-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  count = var.enable_nat_gateway ? 1 : 0

  subnet_id     = aws_subnet.public[0].id
  allocation_id = var.create_eip && length(aws_eip.nat) > 0 ? aws_eip.nat[0].id : null

  depends_on = [aws_internet_gateway.this]

  tags = {
    Name = "${var.vpc_name}-nat"
  }
}

# -------------------
# PRIVATE ROUTE TABLE
# -------------------
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  # Only create route if NAT Gateway is enabled
  dynamic "route" {
    for_each = var.enable_nat_gateway && length(aws_nat_gateway.nat) > 0 ? aws_nat_gateway.nat : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = route.value.id
    }
  }

  tags = {
    Name = "${var.vpc_name}-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnets)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# -------------------
# SECURITY GROUPS
# -------------------
resource "aws_security_group" "ec2_sg" {
  count  = var.create_ec2_sg ? 1 : 0
  vpc_id = aws_vpc.this.id

  dynamic "ingress" {
    for_each = var.ec2_ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vpc_name}-ec2-sg"
  }
}

resource "aws_security_group" "db_sg" {
  count  = var.enable_nat_gateway ? 1 : 0
  vpc_id = aws_vpc.this.id

  ingress {
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = var.create_ec2_sg ? [aws_security_group.ec2_sg[0].id] : []
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vpc_name}-db-sg"
  }
}