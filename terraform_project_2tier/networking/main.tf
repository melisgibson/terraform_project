# --- networking/main.tf ---

data "aws_availability_zones" "available" {}

resource "random_integer" "random" {
  min = 1
  max = 10
}

resource "random_shuffle" "public_az" {
  input        = data.aws_availability_zones.available.names
  result_count = var.max_subnets
}

resource "aws_vpc" "project_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "project-vpc"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "public_subnets" {
  count                   = var.public_sn_count
  vpc_id                  = aws_vpc.project_vpc.id
  cidr_block              = var.public_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = random_shuffle.public_az.result[count.index]

  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnets" {
  count                   = var.private_sn_count
  vpc_id                  = aws_vpc.project_vpc.id
  cidr_block              = var.private_cidrs[count.index]
  map_public_ip_on_launch = false
  availability_zone       = random_shuffle.public_az.result[count.index]

  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}

 # Internet gateway, Elastic IP and Nat gateway

resource "aws_internet_gateway" "project_igw" {
  vpc_id = aws_vpc.project_vpc.id

  tags = {
    Name = "project-igw"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip" "project_nat_eip" {
  vpc = true
}

resource "aws_nat_gateway" "project_ngw" {
  allocation_id     = aws_eip.project_nat_eip.id
  subnet_id         = aws_subnet.public_subnets[1].id
}

# Route tables
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.project_vpc.id

  tags = {
    Name = "public-rt"
  }
}


resource "aws_route" "default_public_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.project_igw.id
}


resource "aws_route_table_association" "public_assoc" {
  count          = var.public_sn_count
  subnet_id      = aws_subnet.public_subnets.*.id[count.index]
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.project_vpc.id

  tags = {
    Name = "private-rt"
  }
}

resource "aws_route" "default_private_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.project_ngw.id
}

resource "aws_route_table_association" "private_assoc" {
  count          = var.private_sn_count
  route_table_id = aws_route_table.private_rt.id
  subnet_id      = aws_subnet.private_subnets.*.id[count.index]
}

# Security groups

resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Allow SSH traffic from set IP"
  vpc_id      = aws_vpc.project_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.access_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "lb_sg" {
  name        = "lb-sg"
  description = "Allow Inbound HTTP Traffic"
  vpc_id      = aws_vpc.project_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow SSH inbound traffic from Bastion, and HTTP inbound traffic from loadbalancer"
  vpc_id      = aws_vpc.project_vpc.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

