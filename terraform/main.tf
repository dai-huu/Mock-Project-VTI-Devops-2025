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
  role_arn = aws_iam_role.HDD-cluster-role.arn # Lấy từ iam_roles.tf
  vpc_config {
    subnet_ids = [
      aws_subnet.HDD-public-subnet-1a.id, # Lấy từ vpc.tf
      aws_subnet.HDD-public-subnet-1c.id,
      aws_subnet.HDD-private-subnet-1a.id,
      aws_subnet.HDD-private-subnet-1c.id
    ]
    endpoint_public_access = true
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
    desired_size = 1
    max_size     = 2
    min_size     = 1
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
    desired_size = 1
    max_size     = 2
    min_size     = 1
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