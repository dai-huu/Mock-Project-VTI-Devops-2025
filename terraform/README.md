# Terraform Configuration for AWS Infrastructure

## Overview
This Terraform configuration sets up a complete AWS infrastructure including a Virtual Private Cloud (VPC), two EKS clusters, and all necessary components:

### Infrastructure Components
- **VPC**: A Virtual Private Cloud to isolate your AWS resources.
- **Subnets**: Public and private subnets across multiple availability zones.
- **Internet Gateway**: To enable internet access for public subnets.
- **NAT Gateway**: To allow private subnets to access the internet securely.
- **Route Tables**: Configured for public and private subnets.
- **EKS Clusters**: Two managed Kubernetes clusters for applications and tech stack.
- **IAM Roles**: Cluster and EBS CSI Driver roles for secure pod identity and add-on management.

## Prerequisites

- **Terraform**: Install Terraform CLI. You can download it from [Terraform Downloads](https://www.terraform.io/downloads).
- **AWS CLI**: Install and configure the AWS CLI with your credentials.
- **AWS Account**: Ensure you have an AWS account with sufficient permissions to create resources.

## Usage

1. **Initialize Terraform**:
   ```bash
   terraform init
   ```

2. **Plan the Infrastructure**:
   ```bash
   terraform plan
   ```

3. **Apply the Configuration**:
   ```bash
   terraform apply
   ```

4. **Destroy the Infrastructure** (if needed):
   ```bash
   terraform destroy
   ```

## Configuration Details

### Provider
- **AWS Region**: `ap-northeast-1` (You can modify this in the `provider` block in `main.tf`.)

### VPC & Network Resources
- **VPC**: CIDR block `10.0.0.0/16`
- **Public Subnets**:
  - `10.0.1.0/24` in `ap-northeast-1a`
  - `10.0.2.0/24` in `ap-northeast-1c`
- **Private Subnets**:
  - `10.0.3.0/24` in `ap-northeast-1a`
  - `10.0.4.0/24` in `ap-northeast-1c`
- **Internet Gateway**: For public subnet internet access.
- **NAT Gateway**: For private subnet internet access.

### EKS Clusters

#### Cluster 1: HDD-eks-application
- **Purpose**: Hosts application workloads.
- **Kubernetes Version**: Latest stable version.
- **Node Group**: `app-workers`
  - **Instance Type**: `t3.medium`
  - **Desired Size**: 2 nodes
  - **Scaling Range**: Min 2, Max 2
- **Authentication Mode**: API and ConfigMap

#### Cluster 2: HDD-eks-techstack
- **Purpose**: Hosts tech stack components.
- **Kubernetes Version**: Latest stable version.
- **Node Group**: `tech-workers`
  - **Instance Type**: `t3.medium`
  - **Desired Size**: 4 nodes
  - **Scaling Range**: Min 4, Max 4
- **Authentication Mode**: API and ConfigMap

### IAM Roles

#### 1. HDD-cluster-role
- **Purpose**: Used by EKS control plane to manage cluster operations.
- **Policy**: `AmazonEKSClusterPolicy`
- **Used by**: Both `HDD-eks-application` and `HDD-eks-techstack` clusters.

#### 2. HDD-EBS-role
- **Purpose**: Used by EBS CSI Driver add-on for managing EBS volumes.
- **Policy**: `AmazonEBSCSIDriverPolicy`
- **Integration**: Configured with OIDC providers for both clusters to allow Pod Identity access.

#### 3. HDD-node-role
- **Purpose**: Used by EKS worker nodes.
- **Policies**:
  - `AmazonEKSWorkerNodePolicy`
  - `AmazonEKS_CNI_Policy`
  - `AmazonEC2ContainerRegistryReadOnly`
  - `AmazonSSMManagedInstanceCore`
  - `AmazonEBSCSIDriverPolicy`
  - `CloudWatchAgentServerPolicy`

### EKS Add-ons

#### Application Cluster Add-ons:
- **vpc-cni**: Manages networking for pods (AWS VPC CNI plugin).
- **coredns**: DNS service for service discovery.
- **kube-proxy**: Manages network rules on worker nodes.
- **aws-ebs-csi-driver**: Manages EBS volume provisioning and attachment.
- **eks-pod-identity-agent**: Enables Pod Identity authentication.
- **eks-node-monitoring-agent**: Provides node monitoring capabilities.
- **external-dns**: Automatically creates DNS records for Kubernetes services.
- **metrics-server**: Provides metrics for autoscaling and monitoring.

#### Techstack Cluster Add-ons:
- Same add-ons as application cluster (see above).

### OIDC Providers
- **Application Cluster OIDC**: Enables Pod Identity for `HDD-eks-application`.
- **Techstack Cluster OIDC**: Enables Pod Identity for `HDD-eks-techstack`.

Both OIDC providers are configured to trust the EBS CSI Driver service account in `kube-system` namespace.

## Notes
- Ensure your AWS credentials are properly configured before running Terraform commands.
- Both EKS clusters share the same VPC and node role for cost optimization.
- The EBS CSI Driver add-on is configured to use a shared IAM role (`HDD-EBS-role`) via OIDC, enabling secure Pod Identity access.
- Node groups are deployed in private subnets for enhanced security.
- Review the `main.tf` and `eks_addons.tf` files to customize the configuration as needed.

## File Structure
```
terraform/
├── main.tf           # VPC, EKS clusters, node groups, IAM roles, and OIDC providers
├── eks_addons.tf     # EKS add-ons for both clusters
├── terraform.tfstate # Terraform state file (tracked in git)
└── README.md         # This documentation
```

## Troubleshooting

### EKS Add-on Issues
- **Unsupported Add-ons**: Some add-ons like `efs-csi-driver` and `eks-pod-identity` may not be supported on specific Kubernetes versions. Check the cluster version with `aws eks describe-cluster --name <cluster-name> --query "cluster.version"`.
- **Policy Not Found**: Ensure the IAM policy exists. For example, verify `AmazonEBSCSIDriverPolicy` exists in your AWS account.
- **Add-on Conflicts**: If add-ons fail with configuration conflicts, delete existing add-ons and reapply:
  ```bash
  aws eks delete-addon --cluster-name <cluster-name> --addon-name <addon-name>
  terraform apply
  ```

### General Issues
- If you encounter issues, check the Terraform logs or AWS Console for more details.
- Ensure your AWS account has sufficient permissions to create the resources defined in this configuration.
- Monitor EKS cluster status in the AWS Console under EKS > Clusters to verify cluster health.