# Manual Setup Guide

This guide provides step-by-step manual instructions for setting up the Solidity Security AWS infrastructure when automated scripts cannot be used.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [AWS Backend Setup](#aws-backend-setup)
3. [Environment Deployment](#environment-deployment)
4. [DNS Configuration](#dns-configuration)
5. [Post-Deployment Configuration](#post-deployment-configuration)
6. [Verification Steps](#verification-steps)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Tools Installation

1. **Install Terraform**
   ```bash
   # Download Terraform 1.5.7 or later
   wget https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip
   unzip terraform_1.5.7_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   terraform version
   ```

2. **Install AWS CLI**
   ```bash
   # Install AWS CLI v2
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   aws --version
   ```

3. **Install kubectl**
   ```bash
   # Install kubectl
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   chmod +x kubectl
   sudo mv kubectl /usr/local/bin/
   kubectl version --client
   ```

### AWS Account Setup

1. **Configure AWS Credentials**
   ```bash
   aws configure
   # Enter your AWS Access Key ID
   # Enter your AWS Secret Access Key
   # Enter your default region (us-east-1)
   # Enter your default output format (json)
   ```

2. **Verify AWS Access**
   ```bash
   aws sts get-caller-identity
   # Should return your account ID, user ARN, and user ID
   ```

3. **Set Environment Variables (Optional)**
   ```bash
   export AWS_DEFAULT_REGION=us-east-1
   export AWS_REGION=us-east-1
   ```

## AWS Backend Setup

### Step 1: Create S3 Bucket for Terraform State

1. **Create S3 Bucket**
   ```bash
   # Replace 'dev' with your environment (dev/staging/production)
   ENVIRONMENT=dev
   BUCKET_NAME="solidity-security-terraform-state-${ENVIRONMENT}"

   aws s3 mb "s3://${BUCKET_NAME}" --region us-east-1
   ```

2. **Enable Bucket Versioning**
   ```bash
   aws s3api put-bucket-versioning \
     --bucket "${BUCKET_NAME}" \
     --versioning-configuration Status=Enabled
   ```

3. **Enable Server-Side Encryption**
   ```bash
   aws s3api put-bucket-encryption \
     --bucket "${BUCKET_NAME}" \
     --server-side-encryption-configuration '{
       "Rules": [
         {
           "ApplyServerSideEncryptionByDefault": {
             "SSEAlgorithm": "AES256"
           }
         }
       ]
     }'
   ```

4. **Block Public Access**
   ```bash
   aws s3api put-public-access-block \
     --bucket "${BUCKET_NAME}" \
     --public-access-block-configuration \
     BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
   ```

### Step 2: Create DynamoDB Table for State Locking

1. **Create DynamoDB Table**
   ```bash
   DYNAMODB_TABLE="solidity-security-terraform-locks-${ENVIRONMENT}"

   aws dynamodb create-table \
     --table-name "${DYNAMODB_TABLE}" \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST \
     --region us-east-1
   ```

2. **Wait for Table to be Active**
   ```bash
   aws dynamodb wait table-exists \
     --table-name "${DYNAMODB_TABLE}" \
     --region us-east-1
   ```

3. **Verify Table Creation**
   ```bash
   aws dynamodb describe-table \
     --table-name "${DYNAMODB_TABLE}" \
     --region us-east-1
   ```

### Step 3: Update Backend Configuration

1. **Navigate to Environment Directory**
   ```bash
   cd terraform/environments/dev
   ```

2. **Update main.tf Backend Configuration**
   Edit the `main.tf` file and update the backend configuration:
   ```hcl
   terraform {
     backend "s3" {
       bucket         = "solidity-security-terraform-state-dev"
       key            = "infrastructure/terraform.tfstate"
       region         = "us-east-1"
       dynamodb_table = "solidity-security-terraform-locks-dev"
       encrypt        = true
     }
   }
   ```

## Environment Deployment

### Step 1: Initialize Terraform

1. **Navigate to Environment Directory**
   ```bash
   cd terraform/environments/dev
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```

3. **Verify Initialization**
   ```bash
   terraform version
   terraform providers
   ```

### Step 2: Validate Configuration

1. **Format Terraform Files**
   ```bash
   terraform fmt -recursive
   ```

2. **Validate Configuration**
   ```bash
   terraform validate
   ```

3. **Check for Syntax Errors**
   ```bash
   terraform plan -detailed-exitcode
   ```

### Step 3: Review and Customize Variables

1. **Edit terraform.tfvars**
   ```bash
   # Copy the example tfvars file
   cp terraform.tfvars.example terraform.tfvars

   # Edit the file with your preferences
   nano terraform.tfvars
   ```

2. **Key Variables to Review**
   ```hcl
   # Basic Configuration
   project_name = "solidity-security"
   environment  = "dev"
   aws_region   = "us-east-1"

   # Network Configuration
   vpc_cidr = "10.0.0.0/16"

   # Domain Configuration
   domain_name       = "advancedblockchainsecurity.com"
   subdomain_prefix  = "dev"

   # EKS Configuration
   node_instance_types = ["t3.medium"]
   node_desired_size   = 2
   node_min_size      = 1
   node_max_size      = 5

   # Cost Optimization
   rds_instance_class = "db.t3.micro"
   elasticache_node_type = "cache.t3.micro"
   ```

### Step 4: Plan Infrastructure Changes

1. **Generate Execution Plan**
   ```bash
   terraform plan -out=tfplan
   ```

2. **Review the Plan**
   - Check resource counts
   - Verify resource configurations
   - Confirm no unexpected deletions
   - Review estimated costs

3. **Save Plan Output (Optional)**
   ```bash
   terraform show tfplan > plan-output.txt
   ```

### Step 5: Apply Infrastructure Changes

1. **Apply the Plan**
   ```bash
   terraform apply tfplan
   ```

2. **Monitor Progress**
   - EKS cluster creation takes 10-15 minutes
   - RDS creation takes 5-10 minutes
   - Total deployment time: 20-30 minutes

3. **Handle Errors**
   If deployment fails:
   ```bash
   # Check the error message
   # Fix any issues
   # Re-run plan and apply
   terraform plan
   terraform apply
   ```

### Step 6: Retrieve Infrastructure Outputs

1. **Get All Outputs**
   ```bash
   terraform output
   ```

2. **Get Specific Outputs**
   ```bash
   # EKS cluster name
   terraform output cluster_id

   # RDS endpoint
   terraform output rds_instance_endpoint

   # Load balancer DNS name (for Cloudflare)
   terraform output alb_dns_name
   ```

3. **Save Outputs for Reference**
   ```bash
   terraform output -json > infrastructure-outputs.json
   ```

## DNS Configuration

### Step 1: Get Load Balancer Information

1. **Get ALB DNS Name**
   ```bash
   # From Terraform output
   ALB_DNS_NAME=$(terraform output -raw alb_dns_name 2>/dev/null || echo "Not yet created")
   echo "ALB DNS Name: $ALB_DNS_NAME"

   # Or from AWS CLI
   aws elbv2 describe-load-balancers \
     --query 'LoadBalancers[?contains(LoadBalancerName, `solidity-security-dev`)].DNSName' \
     --output text
   ```

### Step 2: Configure Cloudflare DNS Records

1. **Login to Cloudflare Dashboard**
   - Go to https://dash.cloudflare.com
   - Select your domain: `advancedblockchainsecurity.com`
   - Navigate to DNS > Records

2. **Add CNAME Records**
   Create the following CNAME records:

   | Type  | Name           | Target (ALB DNS Name) | Proxy Status | TTL  |
   |-------|----------------|-----------------------|--------------|------|
   | CNAME | dev            | `<ALB_DNS_NAME>`      | Proxied      | Auto |
   | CNAME | api.dev        | `<ALB_DNS_NAME>`      | Proxied      | Auto |
   | CNAME | app.dev        | `<ALB_DNS_NAME>`      | Proxied      | Auto |
   | CNAME | argocd.dev     | `<ALB_DNS_NAME>`      | Proxied      | Auto |
   | CNAME | grafana.dev    | `<ALB_DNS_NAME>`      | Proxied      | Auto |
   | CNAME | tools.dev      | `<ALB_DNS_NAME>`      | Proxied      | Auto |

3. **Configure SSL/TLS Settings**
   - Go to SSL/TLS > Overview
   - Set encryption mode to "Full (Strict)"
   - Enable "Always Use HTTPS"

4. **Configure Security Headers**
   - Go to Rules > Transform Rules
   - Add HTTP Response Header Modifications:
     ```
     Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
     X-Content-Type-Options: nosniff
     X-Frame-Options: DENY
     X-XSS-Protection: 1; mode=block
     ```

### Step 3: Verify DNS Resolution

1. **Test DNS Resolution**
   ```bash
   nslookup dev.advancedblockchainsecurity.com
   nslookup api.dev.advancedblockchainsecurity.com
   ```

2. **Test HTTP Response**
   ```bash
   curl -I https://dev.advancedblockchainsecurity.com
   ```

## Post-Deployment Configuration

### Step 1: Configure kubectl Access

1. **Update kubeconfig**
   ```bash
   aws eks update-kubeconfig \
     --region us-east-1 \
     --name solidity-security-dev
   ```

2. **Verify EKS Access**
   ```bash
   kubectl get nodes
   kubectl get namespaces
   ```

3. **Check Cluster Info**
   ```bash
   kubectl cluster-info
   kubectl get pods --all-namespaces
   ```

### Step 2: Create Initial Namespaces

1. **Create Application Namespaces**
   ```bash
   kubectl create namespace argocd
   kubectl create namespace external-secrets
   kubectl create namespace cert-manager
   kubectl create namespace monitoring
   kubectl create namespace solidity-security
   ```

2. **Label Namespaces**
   ```bash
   kubectl label namespace argocd name=argocd
   kubectl label namespace external-secrets name=external-secrets
   kubectl label namespace cert-manager name=cert-manager
   kubectl label namespace monitoring name=monitoring
   kubectl label namespace solidity-security name=solidity-security
   ```

### Step 3: Configure ECR Access

1. **Get ECR Login Token**
   ```bash
   aws ecr get-login-password --region us-east-1 | \
     docker login --username AWS --password-stdin \
     $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com
   ```

2. **List ECR Repositories**
   ```bash
   aws ecr describe-repositories --region us-east-1
   ```

### Step 4: Verify Database Connectivity

1. **Get Database Connection Info**
   ```bash
   DB_ENDPOINT=$(terraform output -raw rds_instance_endpoint)
   DB_SECRET_ARN=$(terraform output -raw rds_secrets_manager_secret_arn)

   echo "Database Endpoint: $DB_ENDPOINT"
   echo "Secret ARN: $DB_SECRET_ARN"
   ```

2. **Test Database Connection (from within EKS)**
   ```bash
   # Create a test pod
   kubectl run postgres-test --image=postgres:15 --rm -it --restart=Never -- \
     psql -h $DB_ENDPOINT -U postgres -d solidity_security
   ```

## Verification Steps

### Step 1: Infrastructure Health Check

1. **Check EKS Cluster Status**
   ```bash
   aws eks describe-cluster --name solidity-security-dev --region us-east-1
   ```

2. **Check RDS Status**
   ```bash
   aws rds describe-db-instances --region us-east-1
   ```

3. **Check ElastiCache Status**
   ```bash
   aws elasticache describe-replication-groups --region us-east-1
   ```

4. **Check Load Balancer Status**
   ```bash
   aws elbv2 describe-load-balancers --region us-east-1
   ```

### Step 2: Network Connectivity Test

1. **Test Internal DNS**
   ```bash
   kubectl run test-pod --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default
   ```

2. **Test External Connectivity**
   ```bash
   kubectl run test-pod --image=busybox --rm -it --restart=Never -- wget -qO- https://google.com
   ```

### Step 3: Security Validation

1. **Check Security Groups**
   ```bash
   aws ec2 describe-security-groups \
     --filters "Name=group-name,Values=*solidity-security-dev*" \
     --region us-east-1
   ```

2. **Verify Encryption Settings**
   ```bash
   # Check EKS encryption
   aws eks describe-cluster --name solidity-security-dev \
     --query 'cluster.encryptionConfig' --region us-east-1

   # Check RDS encryption
   aws rds describe-db-instances \
     --query 'DBInstances[*].StorageEncrypted' --region us-east-1
   ```

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: Terraform Backend Access Denied

**Error:** `Error: error configuring S3 Backend: NoSuchBucket`

**Solution:**
```bash
# Verify bucket exists
aws s3 ls s3://solidity-security-terraform-state-dev

# If bucket doesn't exist, create it
aws s3 mb s3://solidity-security-terraform-state-dev --region us-east-1
```

#### Issue 2: EKS Cluster Access Denied

**Error:** `error: You must be logged in to the server (Unauthorized)`

**Solution:**
```bash
# Update kubeconfig with correct cluster name
aws eks update-kubeconfig --region us-east-1 --name solidity-security-dev

# Verify AWS credentials
aws sts get-caller-identity

# Check if your IAM user/role has EKS permissions
aws eks describe-cluster --name solidity-security-dev --region us-east-1
```

#### Issue 3: RDS Connection Timeout

**Error:** Connection timeouts to RDS instance

**Solution:**
```bash
# Check security group rules
aws ec2 describe-security-groups --group-ids <rds-security-group-id>

# Verify RDS is in the correct subnets
aws rds describe-db-instances --query 'DBInstances[*].DBSubnetGroup'

# Test connectivity from EKS
kubectl run postgres-test --image=postgres:15 --rm -it --restart=Never -- \
  pg_isready -h <rds-endpoint> -p 5432
```

#### Issue 4: DNS Resolution Issues

**Error:** Cannot resolve dev.advancedblockchainsecurity.com

**Solution:**
```bash
# Check Cloudflare DNS records
dig dev.advancedblockchainsecurity.com

# Verify ALB is running
aws elbv2 describe-load-balancers

# Check if ALB DNS name matches Cloudflare CNAME target
terraform output alb_dns_name
```

#### Issue 5: High AWS Costs

**Error:** Unexpected high costs

**Solution:**
```bash
# Check running resources
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name]'

# Check EKS node groups
aws eks describe-nodegroup --cluster-name solidity-security-dev --nodegroup-name <nodegroup-name>

# Consider scaling down for development
# Edit terraform.tfvars:
# node_desired_size = 1
# node_min_size = 1
# rds_instance_class = "db.t3.micro"
```

### Debug Commands

1. **Terraform Debug**
   ```bash
   # Enable detailed logging
   export TF_LOG=DEBUG
   terraform plan

   # Check state
   terraform state list
   terraform state show <resource-name>
   ```

2. **AWS Resource Debug**
   ```bash
   # List all resources with tags
   aws resourcegroupstaggingapi get-resources \
     --tag-filters Key=Project,Values=solidity-security

   # Check CloudTrail for API calls
   aws logs describe-log-groups --log-group-name-prefix /aws/cloudtrail
   ```

3. **Kubernetes Debug**
   ```bash
   # Check node status
   kubectl describe nodes

   # Check system pods
   kubectl get pods -n kube-system

   # Check events
   kubectl get events --sort-by=.metadata.creationTimestamp
   ```

### Getting Help

If you encounter issues not covered in this guide:

1. **Check AWS Documentation**
   - [EKS Troubleshooting](https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html)
   - [RDS Troubleshooting](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Troubleshooting.html)
   - [VPC Troubleshooting](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-troubleshooting.html)

2. **Check Terraform Documentation**
   - [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
   - [Terraform Troubleshooting](https://www.terraform.io/docs/internals/debugging.html)

3. **Community Resources**
   - AWS Community Forums
   - Terraform Community Forums
   - Stack Overflow

4. **Create a GitHub Issue**
   - Include error messages
   - Include Terraform version
   - Include AWS CLI version
   - Include steps to reproduce

---

This manual setup guide provides comprehensive step-by-step instructions for deploying the Solidity Security AWS infrastructure without relying on automation scripts.