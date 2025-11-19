# ==========================================
# 1. IAM ROLES FOR IRSA (EBS CSI)
# ==========================================

# Role Application
resource "aws_iam_role" "HDD-EBS-role-app" {
  name = "HDD-EBS-role-app"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.app_oidc.arn }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.app_oidc.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }]
  })
}
resource "aws_iam_role_policy_attachment" "app_ebs_attach" {
  role       = aws_iam_role.HDD-EBS-role-app.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# Role Techstack
resource "aws_iam_role" "HDD-EBS-role-tech" {
  name = "HDD-EBS-role-tech"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.tech_oidc.arn }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.tech_oidc.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }]
  })
}
resource "aws_iam_role_policy_attachment" "tech_ebs_attach" {
  role       = aws_iam_role.HDD-EBS-role-tech.name
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
resource "aws_eks_addon" "app_ebs_csi" {
  cluster_name             = aws_eks_cluster.HDD-eks-application.name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.HDD-EBS-role-app.arn
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
resource "aws_eks_addon" "tech_ebs_csi" {
  cluster_name             = aws_eks_cluster.HDD-eks-techstack.name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.HDD-EBS-role-tech.arn
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