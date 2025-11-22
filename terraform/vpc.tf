# ==========================================
# NETWORK (VPC & SUBNETS)
# ==========================================

resource "aws_vpc" "HDD-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "HDD-vpc" }
}

# Public Subnets
resource "aws_subnet" "HDD-public-subnet-1a" {
  vpc_id                  = aws_vpc.HDD-vpc.id
  cidr_block              = "10.0.0.0/18"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true
  tags = { Name = "HDD-public-subnet-1a" }
}

resource "aws_subnet" "HDD-public-subnet-1c" {
  vpc_id                  = aws_vpc.HDD-vpc.id
  cidr_block              = "10.0.64.0/18"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = true
  tags = { Name = "HDD-public-subnet-1c" }
}

# Private Subnets
resource "aws_subnet" "HDD-private-subnet-1a" {
  vpc_id            = aws_vpc.HDD-vpc.id
  cidr_block        = "10.0.128.0/18"
  availability_zone = "ap-northeast-1a"
  tags = { Name = "HDD-private-subnet-1a" }
}

resource "aws_subnet" "HDD-private-subnet-1c" {
  vpc_id            = aws_vpc.HDD-vpc.id
  cidr_block        = "10.0.192.0/18"
  availability_zone = "ap-northeast-1c"
  tags = { Name = "HDD-private-subnet-1c" }
}

# Gateways & Routes
resource "aws_internet_gateway" "HDD-internet-gateway" {
  vpc_id = aws_vpc.HDD-vpc.id
  tags = { Name = "HDD-internet-gateway" }
}

resource "aws_eip" "HDD-nat-eip" {
  domain     = "vpc"
  tags       = { Name = "HDD-nat-eip" }
  depends_on = [aws_internet_gateway.HDD-internet-gateway]
}

resource "aws_nat_gateway" "HDD-nat-gateway" {
  allocation_id = aws_eip.HDD-nat-eip.id
  subnet_id     = aws_subnet.HDD-public-subnet-1a.id
  tags          = { Name = "HDD-nat-gateway" }
  depends_on    = [aws_internet_gateway.HDD-internet-gateway]
}

resource "aws_route_table" "HDD-rtb-public" {
  vpc_id = aws_vpc.HDD-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.HDD-internet-gateway.id
  }
  tags = { Name = "HDD-rtb-public" }
}

resource "aws_route_table" "HDD-rtb-private" {
  vpc_id = aws_vpc.HDD-vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.HDD-nat-gateway.id
  }
  tags = { Name = "HDD-rtb-private" }
}

resource "aws_route_table_association" "pub_1a" {
  subnet_id      = aws_subnet.HDD-public-subnet-1a.id
  route_table_id = aws_route_table.HDD-rtb-public.id
}
resource "aws_route_table_association" "pub_1c" {
  subnet_id      = aws_subnet.HDD-public-subnet-1c.id
  route_table_id = aws_route_table.HDD-rtb-public.id
}
resource "aws_route_table_association" "priv_1a" {
  subnet_id      = aws_subnet.HDD-private-subnet-1a.id
  route_table_id = aws_route_table.HDD-rtb-private.id
}
resource "aws_route_table_association" "priv_1c" {
  subnet_id      = aws_subnet.HDD-private-subnet-1c.id
  route_table_id = aws_route_table.HDD-rtb-private.id
}