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
# Terraform Configuration for AWS Infrastructure

## Overview
This Terraform configuration creates the following AWS infrastructure (exact resources are declared in the `*.tf` files):

- VPC with public & private subnets
- Internet Gateway and NAT Gateway
- Route tables and associations for public/private subnets
- Two EKS clusters (`HDD-eks-application` and `HDD-eks-techstack`)
- Node groups for each cluster
- IAM roles for cluster control plane, worker nodes and a shared EBS CSI IRSA role
- EKS add-ons (CNI, CoreDNS, kube-proxy, EBS CSI driver, pod identity agent, monitoring, external-dns, metrics-server)

**Region:** `ap-northeast-1` (configured in `main.tf` provider block)

## Key resource values (as declared in the code)

- VPC: `10.0.0.0/16`
- Public subnets:
  - `HDD-public-subnet-1a` — `10.0.0.0/18` (AZ `ap-northeast-1a`, public)
  - `HDD-public-subnet-1c` — `10.0.64.0/18` (AZ `ap-northeast-1c`, public)
- Private subnets:
  - `HDD-private-subnet-1a` — `10.0.128.0/18` (AZ `ap-northeast-1a`)
  - `HDD-private-subnet-1c` — `10.0.192.0/18` (AZ `ap-northeast-1c`)
- NAT Gateway: Elastic IP + NAT in `HDD-public-subnet-1a`

### EKS clusters

- `HDD-eks-application` (cluster)
  - Node group `app-workers` — `t3.medium`, desired=3, min=3, max=3
  - Cluster `access_config` uses `API_AND_CONFIG_MAP` authentication

- `HDD-eks-techstack` (cluster)
  - Node group `tech-workers` — `t3.medium`, desired=5, min=5, max=5
  - Cluster `access_config` uses `API_AND_CONFIG_MAP` authentication

### IAM & OIDC

- `HDD-cluster-role`: attached `AmazonEKSClusterPolicy` (used by control planes)
- `HDD-node-role`: attached multiple managed policies for worker nodes (EKS worker, CNI, ECR read-only, SSM, EBS CSI, CloudWatch)
- `HDD-EBS-role`: shared IRSA role for the EBS CSI driver; its assume-role includes both clusters' OIDC providers and the `kube-system:ebs-csi-controller-sa` service account

### Add-ons (both clusters)

- `vpc-cni`, `coredns`, `kube-proxy`, `aws-ebs-csi-driver` (uses `HDD-EBS-role`), `eks-pod-identity-agent`, `eks-node-monitoring-agent`, `external-dns`, `metrics-server`

### Cluster access/users

- `eks_access.tf` creates `aws_eks_access_entry` and `aws_eks_access_policy_association` for a list of admin ARNs (local list `all_admin_users`) and filters out the caller executing Terraform so the caller is assumed bootstraped.

### Security group rules

- Terraform finds the EKS cluster security groups by name pattern and creates bi-directional SG rules allowing all traffic between application and techstack clusters (used for inter-cluster communications).

## Usage

Run the usual Terraform workflow:

```powershell
terraform init
terraform plan
terraform apply
terraform destroy
```

## Important notes & recommendations

- The repository currently contains `terraform.tfstate` and `terraform.tfstate.backup` under the `terraform/` folder. These files contain sensitive and environment-specific data and should NOT be committed to Git.
  - Recommended: remove the files from Git and configure a remote backend (S3 + DynamoDB lock). Example commands:

```powershell
git rm --cached terraform/terraform.tfstate terraform/terraform.tfstate.backup
echo "terraform/terraform.tfstate" >> .gitignore
git commit -m "Remove terraform state from repo and add to gitignore"
```

  - Example backend snippet (add to a `backend.tf` or inside `terraform` block):

```hcl
terraform {
  backend "s3" {
    bucket         = "<your-terraform-state-bucket>"
    key            = "mock-pj/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "<your-lock-table>"
  }
}
```

- Parameterize hard-coded values (region, AZs, CIDR blocks, instance types, node counts, admin ARNs) by moving them to `variables.tf` so the configuration is reusable across environments.
- Review IAM policies and follow least-privilege: currently several managed policies are attached to the node role for convenience.
- Verify EKS add-on compatibility with your target Kubernetes version before applying.

## Suggested next steps

- Remove `terraform.tfstate` from the repository and configure a remote backend (S3 + DynamoDB).
- Create `variables.tf` and update `.tf` files to use variables for region, AZs, CIDRs, instance types and node counts.
- Optionally add `outputs.tf` for important values such as cluster names and kubeconfig data.

## File structure (relevant files)

```
terraform/
├── main.tf
├── vpc.tf
├── iam_roles.tf
├── eks_access.tf
├── eks_addons.tf
├── terraform.tfstate                # currently present in repo — remove it
└── README.md
```

If you want, mình có thể:
- tạo `variables.tf` và refactor các giá trị hard-coded thành biến;
- hoặc tạo `backend.tf` mẫu và hướng dẫn di chuyển state lên S3.
