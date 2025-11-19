# 1. CLUSTER ROLE (Cho Control Plane)
resource "aws_iam_role" "HDD-cluster-role" {
  name = "HDD-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "eks.amazonaws.com" } }]
  })
}
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.HDD-cluster-role.name
}

# 2. NODE GROUP ROLE (Cho Worker Nodes - Full 6 quyền)
resource "aws_iam_role" "HDD-node-role" {
  name = "HDD-node-group-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" } }]
  })
}

# Gắn 6 policies vào Node Role
resource "aws_iam_role_policy_attachment" "node_WorkerNode" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.HDD-node-role.name
}
resource "aws_iam_role_policy_attachment" "node_CNI" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.HDD-node-role.name
}
resource "aws_iam_role_policy_attachment" "node_ECR" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.HDD-node-role.name
}
resource "aws_iam_role_policy_attachment" "node_SSM" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.HDD-node-role.name
}
resource "aws_iam_role_policy_attachment" "node_EBS" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.HDD-node-role.name
}
resource "aws_iam_role_policy_attachment" "node_CloudWatch" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.HDD-node-role.name
}