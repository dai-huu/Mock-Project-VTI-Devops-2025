# ==========================================
# 0. LẤY THÔNG TIN NGƯỜI ĐANG CHẠY TERRAFORM
# ==========================================
data "aws_caller_identity" "current" {}

# ==========================================
# DANH SÁCH USER CẦN CẤP QUYỀN
# ==========================================
locals {
  # Bạn cứ liệt kê ĐẦY ĐỦ TẤT CẢ user vào đây (không cần quan tâm ai chạy)
  all_admin_users = [
    "arn:aws:iam::906034468113:user/DE000112",
    "arn:aws:iam::906034468113:user/hohuudai-eks-controller",
    "arn:aws:iam::906034468113:user/DE000109",
    "arn:aws:iam::906034468113:user/datdt-eks-controller",
    "arn:aws:iam::906034468113:user/DE000116",
    "arn:aws:iam::906034468113:user/haint-eks-controller"
  ]

  # LOGIC THÔNG MINH:
  # Tạo danh sách mới, loại bỏ người đang chạy lệnh (vì người này đã được bootstrap = true lo rồi)
  # Nếu hohuudai chạy -> List này sẽ mất hohuudai, giữ haint
  # Nếu haint chạy    -> List này sẽ mất haint, giữ hohuudai
  final_admin_users = [
    for user in local.all_admin_users : user
    if user != data.aws_caller_identity.current.arn
  ]
}

# ==========================================
# 1. CẤP QUYỀN CHO CLUSTER: APPLICATION
# ==========================================

resource "aws_eks_access_entry" "app_access_entries" {
  for_each      = toset(local.final_admin_users) # Dùng danh sách đã lọc
  cluster_name  = aws_eks_cluster.HDD-eks-application.name
  principal_arn = each.value
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "app_policy_assoc" {
  for_each      = toset(local.final_admin_users)
  cluster_name  = aws_eks_cluster.HDD-eks-application.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = each.value

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.app_access_entries]
}

# ==========================================
# 2. CẤP QUYỀN CHO CLUSTER: TECHSTACK
# ==========================================

resource "aws_eks_access_entry" "tech_access_entries" {
  for_each      = toset(local.final_admin_users) # Dùng danh sách đã lọc
  cluster_name  = aws_eks_cluster.HDD-eks-techstack.name
  principal_arn = each.value
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "tech_policy_assoc" {
  for_each      = toset(local.final_admin_users)
  cluster_name  = aws_eks_cluster.HDD-eks-techstack.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = each.value

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.tech_access_entries]
}