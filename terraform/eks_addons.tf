# ==========================================
# 1. SHARED IAM ROLE FOR EBS CSI (IRSA)
# ==========================================

# Tạo 1 Role duy nhất tên là "HDD-EBS-role" dùng cho cả 2 Cluster
resource "aws_iam_role" "HDD-EBS-role" {
  name = "HDD-EBS-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Statement 1: Cho phép Cluster Application
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.app_oidc.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.app_oidc.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      },
      # Statement 2: Cho phép Cluster Techstack
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.tech_oidc.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.tech_oidc.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      }
    ]
  })
}

# Gắn quyền EBS cho Role chung này
resource "aws_iam_role_policy_attachment" "shared_ebs_attach" {
  role       = aws_iam_role.HDD-EBS-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}


# ==========================================
# 2. ADD-ONS (App Cluster)
# ==========================================
resource "aws_eks_addon" "app_vpc_cni" {
  cluster_name = aws_eks_cluster.HDD-eks-application.name
  addon_name   = "vpc-cni"
  depends_on   = [aws_eks_node_group.app_node_group]
}
resource "aws_eks_addon" "app_coredns" {
  cluster_name = aws_eks_cluster.HDD-eks-application.name
  addon_name   = "coredns"
  depends_on   = [aws_eks_node_group.app_node_group]
}
resource "aws_eks_addon" "app_kube_proxy" {
  cluster_name = aws_eks_cluster.HDD-eks-application.name
  addon_name   = "kube-proxy"
  depends_on   = [aws_eks_node_group.app_node_group]
}
# EBS Addon dùng Role chung
resource "aws_eks_addon" "app_ebs_csi" {
  cluster_name             = aws_eks_cluster.HDD-eks-application.name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.HDD-EBS-role.arn # <--- Trỏ vào Role chung
  depends_on               = [aws_eks_node_group.app_node_group]
}
resource "aws_eks_addon" "app_pod_identity" {
  cluster_name = aws_eks_cluster.HDD-eks-application.name
  addon_name   = "eks-pod-identity-agent"
  depends_on   = [aws_eks_node_group.app_node_group]
}
resource "aws_eks_addon" "app_monitoring" {
  cluster_name = aws_eks_cluster.HDD-eks-application.name
  addon_name   = "eks-node-monitoring-agent"
  depends_on   = [aws_eks_node_group.app_node_group]
}
resource "aws_eks_addon" "app_external_dns" {
  cluster_name = aws_eks_cluster.HDD-eks-application.name
  addon_name   = "external-dns"
  depends_on   = [aws_eks_node_group.app_node_group]
}
resource "aws_eks_addon" "app_metrics_server" {
  cluster_name = aws_eks_cluster.HDD-eks-application.name
  addon_name   = "metrics-server"
  depends_on   = [aws_eks_node_group.app_node_group]
}


# ==========================================
# 3. ADD-ONS (Techstack Cluster)
# ==========================================
resource "aws_eks_addon" "tech_vpc_cni" {
  cluster_name = aws_eks_cluster.HDD-eks-techstack.name
  addon_name   = "vpc-cni"
  depends_on   = [aws_eks_node_group.tech_node_group]
}
resource "aws_eks_addon" "tech_coredns" {
  cluster_name = aws_eks_cluster.HDD-eks-techstack.name
  addon_name   = "coredns"
  depends_on   = [aws_eks_node_group.tech_node_group]
}
resource "aws_eks_addon" "tech_kube_proxy" {
  cluster_name = aws_eks_cluster.HDD-eks-techstack.name
  addon_name   = "kube-proxy"
  depends_on   = [aws_eks_node_group.tech_node_group]
}
# EBS Addon dùng Role chung
resource "aws_eks_addon" "tech_ebs_csi" {
  cluster_name             = aws_eks_cluster.HDD-eks-techstack.name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.HDD-EBS-role.arn # <--- Trỏ vào Role chung
  depends_on               = [aws_eks_node_group.tech_node_group]
}
resource "aws_eks_addon" "tech_pod_identity" {
  cluster_name = aws_eks_cluster.HDD-eks-techstack.name
  addon_name   = "eks-pod-identity-agent"
  depends_on   = [aws_eks_node_group.tech_node_group]
}
resource "aws_eks_addon" "tech_monitoring" {
  cluster_name = aws_eks_cluster.HDD-eks-techstack.name
  addon_name   = "eks-node-monitoring-agent"
  depends_on   = [aws_eks_node_group.tech_node_group]
}
resource "aws_eks_addon" "tech_external_dns" {
  cluster_name = aws_eks_cluster.HDD-eks-techstack.name
  addon_name   = "external-dns"
  depends_on   = [aws_eks_node_group.tech_node_group]
}
resource "aws_eks_addon" "tech_metrics_server" {
  cluster_name = aws_eks_cluster.HDD-eks-techstack.name
  addon_name   = "metrics-server"
  depends_on   = [aws_eks_node_group.tech_node_group]
}