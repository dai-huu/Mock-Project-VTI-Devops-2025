terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.21.0"
    }
  }
}

# Cấu hình nhà cung cấp dịch vụ AWS
provider "aws" {
  region = "ap-northeast-1" # Bạn có thể thay đổi region tại đây
}

# Tạo một VPC
resource "aws_vpc" "HDD-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "HDD-vpc"
  }
}

# Tạo hai Subnet công cộng (public subnets) ở hai Availability Zones
resource "aws_subnet" "HDD-public-subnet-1a" {
  vpc_id     = aws_vpc.HDD-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "HDD-public-subnet-1a"
  }
}

resource "aws_subnet" "HDD-public-subnet-1c" {
  vpc_id     = aws_vpc.HDD-vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "HDD-public-subnet-1c"
  }
}

# Tạo hai Subnet riêng tư (private subnets) ở hai Availability Zones
resource "aws_subnet" "HDD-private-subnet-1a" {
  vpc_id     = aws_vpc.HDD-vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "HDD-private-subnet-1a"
  }
}

resource "aws_subnet" "HDD-private-subnet-1c" {
  vpc_id     = aws_vpc.HDD-vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "HDD-private-subnet-1c"
  }
}

# Tạo một Internet Gateway mới
resource "aws_internet_gateway" "HDD-internet-gateway" {
  vpc_id = aws_vpc.HDD-vpc.id

  tags = {
    Name = "HDD-internet-gateway"
  }
}

# Cập nhật Route Table công cộng để sử dụng Internet Gateway mới
resource "aws_route_table" "HDD-rtb-public" {
  vpc_id = aws_vpc.HDD-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.HDD-internet-gateway.id
  }

  tags = {
    Name = "HDD-rtb-public"
  }
}

# Tạo Elastic IP cho NAT Gateway
resource "aws_eip" "HDD-nat-eip" {
  domain = "vpc"

  tags = {
    Name = "HDD-nat-eip"
  }

  depends_on = [aws_internet_gateway.HDD-internet-gateway]
}

# Tạo NAT Gateway
resource "aws_nat_gateway" "HDD-nat-gateway" {
  allocation_id = aws_eip.HDD-nat-eip.id
  subnet_id     = aws_subnet.HDD-public-subnet-1a.id

  tags = {
    Name = "HDD-nat-gateway"
  }

  depends_on = [aws_internet_gateway.HDD-internet-gateway]
}

# Tạo Route Table riêng tư (private route table)
resource "aws_route_table" "HDD-rtb-private" {
  vpc_id = aws_vpc.HDD-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.HDD-nat-gateway.id
  }

  tags = {
    Name = "HDD-rtb-private"
  }
}

# Liên kết Route Table công cộng với các Public Subnet
resource "aws_route_table_association" "HDD-rtb-public-1a" {
  subnet_id      = aws_subnet.HDD-public-subnet-1a.id
  route_table_id = aws_route_table.HDD-rtb-public.id
}

resource "aws_route_table_association" "HDD-rtb-public-1c" {
  subnet_id      = aws_subnet.HDD-public-subnet-1c.id
  route_table_id = aws_route_table.HDD-rtb-public.id
}

# Liên kết Route Table riêng tư với các Private Subnet
resource "aws_route_table_association" "HDD-rtb-private-1a" {
  subnet_id      = aws_subnet.HDD-private-subnet-1a.id
  route_table_id = aws_route_table.HDD-rtb-private.id
}

resource "aws_route_table_association" "HDD-rtb-private-1c" {
  subnet_id      = aws_subnet.HDD-private-subnet-1c.id
  route_table_id = aws_route_table.HDD-rtb-private.id
}

# Create an IAM Role for EKS
resource "aws_iam_role" "HDD-cluster-role" {
  name = "HDD-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "HDD-cluster-role"
  }
}

# Attach AdministratorAccess policy to the IAM Role
resource "aws_iam_role_policy_attachment" "HDD-cluster-role-attachment" {
  role       = aws_iam_role.HDD-cluster-role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Create EKS Cluster for Application
resource "aws_eks_cluster" "HDD-eks-application" {
  name     = "HDD-eks-application"
  role_arn = aws_iam_role.HDD-cluster-role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.HDD-public-subnet-1a.id,
      aws_subnet.HDD-public-subnet-1c.id
    ]
    endpoint_public_access = true
    endpoint_private_access = true
  }

  tags = {
    Name = "HDD-eks-application"
  }
}

# Create EKS Cluster for Techstack
resource "aws_eks_cluster" "HDD-eks-techstack" {
  name     = "HDD-eks-techstack"
  role_arn = aws_iam_role.HDD-cluster-role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.HDD-public-subnet-1a.id,
      aws_subnet.HDD-public-subnet-1c.id
    ]
    endpoint_public_access = true
    endpoint_private_access = true
  }

  tags = {
    Name = "HDD-eks-techstack"
  }
}



