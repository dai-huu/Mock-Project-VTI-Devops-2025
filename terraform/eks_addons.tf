# Create IAM Role for EBS CSI Driver
resource "aws_iam_role" "HDD-EBS-role" {
  name = "HDD-EBS-role"

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
    Name = "HDD-EBS-role"
  }
}

# Attach AmazonEBSCSIDriverPolicy to the IAM Role
resource "aws_iam_role_policy_attachment" "HDD-EBS-role-policy" {
  role       = aws_iam_role.HDD-EBS-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEBSCSIDriverPolicy"
}



# Add-ons for HDD-eks-application
resource "aws_eks_addon" "application_kube_proxy" {
  cluster_name = aws_eks_cluster.HDD-eks-application.name
  addon_name   = "kube-proxy"
}

resource "aws_eks_addon" "application_coredns" {
  cluster_name = aws_eks_cluster.HDD-eks-application.name
  addon_name   = "coredns"
}

resource "aws_eks_addon" "application_vpc_cni" {
  cluster_name = aws_eks_cluster.HDD-eks-application.name
  addon_name   = "vpc-cni"
}

resource "aws_eks_addon" "application_efs_csi" {
  cluster_name = aws_eks_cluster.HDD-eks-application.name
  addon_name   = "efs-csi-driver"
}

resource "aws_eks_addon" "application_pod_identity" {
  cluster_name = aws_eks_cluster.HDD-eks-application.name
  addon_name   = "eks-pod-identity"
}

resource "aws_eks_addon" "application_external_dns" {
  cluster_name = aws_eks_cluster.HDD-eks-application.name
  addon_name   = "external-dns"
}

resource "aws_eks_addon" "application_metrics_server" {
  cluster_name = aws_eks_cluster.HDD-eks-application.name
  addon_name   = "metrics-server"
}

resource "aws_eks_addon" "application_ebs_csi" {
  cluster_name = aws_eks_cluster.HDD-eks-application.name
  addon_name   = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.HDD-EBS-role.arn
}



# Add-ons for HDD-eks-techstack
resource "aws_eks_addon" "techstack_kube_proxy" {
  cluster_name = aws_eks_cluster.HDD-eks-techstack.name
  addon_name   = "kube-proxy"
}

resource "aws_eks_addon" "techstack_coredns" {
  cluster_name = aws_eks_cluster.HDD-eks-techstack.name
  addon_name   = "coredns"
}

resource "aws_eks_addon" "techstack_vpc_cni" {
  cluster_name = aws_eks_cluster.HDD-eks-techstack.name
  addon_name   = "vpc-cni"
}

resource "aws_eks_addon" "techstack_efs_csi" {
  cluster_name = aws_eks_cluster.HDD-eks-techstack.name
  addon_name   = "efs-csi-driver"
}

resource "aws_eks_addon" "techstack_pod_identity" {
  cluster_name = aws_eks_cluster.HDD-eks-techstack.name
  addon_name   = "eks-pod-identity"
}

resource "aws_eks_addon" "techstack_external_dns" {
  cluster_name = aws_eks_cluster.HDD-eks-techstack.name
  addon_name   = "external-dns"
}

resource "aws_eks_addon" "techstack_metrics_server" {
  cluster_name = aws_eks_cluster.HDD-eks-techstack.name
  addon_name   = "metrics-server"
}

resource "aws_eks_addon" "techstack_ebs_csi" {
  cluster_name = aws_eks_cluster.HDD-eks-techstack.name
  addon_name   = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.HDD-EBS-role.arn
}