terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.21.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

# ==========================================
# CLUSTERS & NODE GROUPS
# ==========================================

# --- Cluster 1: Application ---
resource "aws_eks_cluster" "HDD-eks-application" {
  name     = "HDD-eks-application"
  role_arn = aws_iam_role.HDD-cluster-role.arn
  
  vpc_config {
    subnet_ids = [
      aws_subnet.HDD-public-subnet-1a.id,
      aws_subnet.HDD-public-subnet-1c.id,
      aws_subnet.HDD-private-subnet-1a.id,
      aws_subnet.HDD-private-subnet-1c.id
    ]
    endpoint_public_access = true
  }

  # [MỚI - QUAN TRỌNG] Bật chế độ xác thực API để dùng Access Entry
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy]
}

# OIDC Application
data "tls_certificate" "app_tls" {
  url = aws_eks_cluster.HDD-eks-application.identity[0].oidc[0].issuer
}
resource "aws_iam_openid_connect_provider" "app_oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.app_tls.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.HDD-eks-application.identity[0].oidc[0].issuer
}

# Node Group Application
resource "aws_eks_node_group" "app_node_group" {
  cluster_name    = aws_eks_cluster.HDD-eks-application.name
  node_group_name = "app-workers"
  node_role_arn   = aws_iam_role.HDD-node-role.arn
  subnet_ids      = [aws_subnet.HDD-private-subnet-1a.id, aws_subnet.HDD-private-subnet-1c.id]
  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 3
  }
  instance_types = ["t3.medium"]
  
  depends_on = [
    aws_iam_role_policy_attachment.node_WorkerNode,
    aws_iam_role_policy_attachment.node_CNI,
    aws_iam_role_policy_attachment.node_ECR,
    aws_iam_role_policy_attachment.node_SSM,
    aws_iam_role_policy_attachment.node_EBS,
    aws_iam_role_policy_attachment.node_CloudWatch
  ]
}

# --- Cluster 2: Techstack ---
resource "aws_eks_cluster" "HDD-eks-techstack" {
  name     = "HDD-eks-techstack"
  role_arn = aws_iam_role.HDD-cluster-role.arn
  
  vpc_config {
    subnet_ids = [
      aws_subnet.HDD-public-subnet-1a.id,
      aws_subnet.HDD-public-subnet-1c.id,
      aws_subnet.HDD-private-subnet-1a.id,
      aws_subnet.HDD-private-subnet-1c.id
    ]
    endpoint_public_access = true
  }

  # [MỚI - QUAN TRỌNG] Bật chế độ xác thực API
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy]
}

# OIDC Techstack
data "tls_certificate" "tech_tls" {
  url = aws_eks_cluster.HDD-eks-techstack.identity[0].oidc[0].issuer
}
resource "aws_iam_openid_connect_provider" "tech_oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.tech_tls.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.HDD-eks-techstack.identity[0].oidc[0].issuer
}

# Node Group Techstack
resource "aws_eks_node_group" "tech_node_group" {
  cluster_name    = aws_eks_cluster.HDD-eks-techstack.name
  node_group_name = "tech-workers"
  node_role_arn   = aws_iam_role.HDD-node-role.arn
  subnet_ids      = [aws_subnet.HDD-private-subnet-1a.id, aws_subnet.HDD-private-subnet-1c.id]
  scaling_config {
    desired_size = 5
    max_size     = 5
    min_size     = 5
  }
  instance_types = ["t3.medium"]
  
  depends_on = [
    aws_iam_role_policy_attachment.node_WorkerNode,
    aws_iam_role_policy_attachment.node_CNI,
    aws_iam_role_policy_attachment.node_ECR,
    aws_iam_role_policy_attachment.node_SSM,
    aws_iam_role_policy_attachment.node_EBS,
    aws_iam_role_policy_attachment.node_CloudWatch
  ]
}

# ==========================================
# SECURITY GROUP RULES - INTER-CLUSTER COMMUNICATION
# ==========================================

# Get security groups từ cả 2 clusters
data "aws_security_group" "app_cluster_sg" {
  filter {
    name   = "group-name"
    values = ["eks-cluster-sg-${aws_eks_cluster.HDD-eks-application.name}-*"]
  }
  filter {
    name   = "vpc-id"
    values = [aws_vpc.HDD-vpc.id]
  }
  depends_on = [aws_eks_cluster.HDD-eks-application]
}

data "aws_security_group" "tech_cluster_sg" {
  filter {
    name   = "group-name"
    values = ["eks-cluster-sg-${aws_eks_cluster.HDD-eks-techstack.name}-*"]
  }
  filter {
    name   = "vpc-id"
    values = [aws_vpc.HDD-vpc.id]
  }
  depends_on = [aws_eks_cluster.HDD-eks-techstack]
}

# Allow all inbound traffic từ Application cluster SG đến Techstack cluster SG
resource "aws_security_group_rule" "app_to_tech_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  source_security_group_id = data.aws_security_group.app_cluster_sg.id
  security_group_id = data.aws_security_group.tech_cluster_sg.id
  description       = "Allow all traffic from Application cluster to Techstack cluster"
  depends_on = [data.aws_security_group.app_cluster_sg, data.aws_security_group.tech_cluster_sg]
}

# Allow all inbound traffic từ Techstack cluster SG đến Application cluster SG
resource "aws_security_group_rule" "tech_to_app_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  source_security_group_id = data.aws_security_group.tech_cluster_sg.id
  security_group_id = data.aws_security_group.app_cluster_sg.id
  description       = "Allow all traffic from Techstack cluster to Application cluster"
  depends_on = [data.aws_security_group.app_cluster_sg, data.aws_security_group.tech_cluster_sg]
}