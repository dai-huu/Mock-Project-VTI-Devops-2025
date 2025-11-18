# Terraform Configuration for AWS Infrastructure

## Overview
This Terraform configuration sets up a Virtual Private Cloud (VPC) on AWS with the following components:

- **VPC**: A Virtual Private Cloud to isolate your AWS resources.
- **Subnets**: Public and private subnets across multiple availability zones.
- **Internet Gateway**: To enable internet access for public subnets.
- **NAT Gateway**: To allow private subnets to access the internet securely.
- **Route Tables**: Configured for public and private subnets.

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

### Resources
- **VPC**: CIDR block `10.0.0.0/16`
- **Public Subnets**:
  - `10.0.1.0/24` in `ap-northeast-1a`
  - `10.0.2.0/24` in `ap-northeast-1c`
- **Private Subnets**:
  - `10.0.3.0/24` in `ap-northeast-1a`
  - `10.0.4.0/24` in `ap-northeast-1c`
- **Internet Gateway**: For public subnet internet access.
- **NAT Gateway**: For private subnet internet access.

### Tags
All resources are tagged with a `Name` tag for easy identification.

## Notes
- Ensure your AWS credentials are properly configured before running Terraform commands.
- Review the `main.tf` file to customize the configuration as needed.

## Troubleshooting
- If you encounter issues, check the Terraform logs or AWS Console for more details.
- Ensure your AWS account has sufficient permissions to create the resources defined in this configuration.