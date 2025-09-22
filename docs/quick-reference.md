# Quick Reference Guide

This is a quick reference for common commands and operations for the Solidity Security AWS Infrastructure.

## Scripts Overview

### Setup Backend Script
```bash
# Create S3 bucket and DynamoDB table for Terraform state
./scripts/setup-backend.sh <environment> [aws-region]

# Examples
./scripts/setup-backend.sh dev
./scripts/setup-backend.sh staging us-east-1
./scripts/setup-backend.sh production us-west-2
```

### Deploy Environment Script
```bash
# Deploy infrastructure to an environment
./scripts/deploy-env.sh <environment> [aws-region] [action]

# Examples
./scripts/deploy-env.sh dev us-east-1 plan    # Plan only
./scripts/deploy-env.sh dev us-east-1 apply   # Deploy
./scripts/deploy-env.sh dev us-east-1 destroy # Destroy
```

## Common Commands

### Initial Setup
```bash
# 1. Clone repository
git clone <repository-url>
cd solidity-security-aws-infrastructure

# 2. Configure AWS
aws configure

# 3. Setup backend and deploy
./scripts/setup-backend.sh dev
./scripts/deploy-env.sh dev us-east-1 apply

# 4. Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name solidity-security-dev
```

### Manual Terraform Commands
```bash
# Navigate to environment
cd terraform/environments/dev

# Initialize
terraform init

# Plan
terraform plan

# Apply
terraform apply

# Destroy
terraform destroy

# Get outputs
terraform output
```

### Useful AWS Commands
```bash
# Get cluster info
aws eks describe-cluster --name solidity-security-dev --region us-east-1

# Get RDS info
aws rds describe-db-instances --region us-east-1

# Get load balancer info
aws elbv2 describe-load-balancers --region us-east-1

# Get ECR repositories
aws ecr describe-repositories --region us-east-1
```

### Kubernetes Commands
```bash
# Get nodes
kubectl get nodes

# Get namespaces
kubectl get namespaces

# Get all pods
kubectl get pods --all-namespaces

# Create namespace
kubectl create namespace <namespace-name>

# Get cluster info
kubectl cluster-info
```

### DNS and Connectivity
```bash
# Test DNS resolution
nslookup dev.advancedblockchainsecurity.com

# Test HTTPS
curl -I https://dev.advancedblockchainsecurity.com

# ECR login
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
```

## Environment Variables

### For Scripts
```bash
export AWS_DEFAULT_REGION=us-east-1
export AWS_REGION=us-east-1
```

### For Terraform
```bash
export TF_LOG=DEBUG              # Enable debug logging
export TF_VAR_environment=dev    # Set Terraform variable
```

## File Locations

### Configuration Files
- Environment configs: `terraform/environments/{dev,staging,production}/`
- Module definitions: `terraform/modules/`
- Variables: `terraform/environments/*/terraform.tfvars`

### Documentation
- Manual setup: `docs/manual-setup.md`
- DNS setup: `cloudflare/dns-configuration.md`
- Quick reference: `docs/quick-reference.md` (this file)

### Scripts
- Backend setup: `scripts/setup-backend.sh`
- Environment deployment: `scripts/deploy-env.sh`

## Troubleshooting Quick Fixes

### Terraform Issues
```bash
# State lock issue
terraform force-unlock <lock-id>

# Refresh state
terraform refresh

# Import existing resource
terraform import <resource-type>.<resource-name> <resource-id>
```

### AWS Access Issues
```bash
# Check credentials
aws sts get-caller-identity

# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name solidity-security-dev

# List profiles
aws configure list-profiles
```

### Kubernetes Issues
```bash
# Check cluster connection
kubectl cluster-info

# Check node status
kubectl get nodes -o wide

# Check system pods
kubectl get pods -n kube-system

# Describe failing pod
kubectl describe pod <pod-name> -n <namespace>
```

## Security Reminders

- Never commit `terraform.tfvars` files with sensitive data
- Use AWS Secrets Manager for application secrets
- Keep Terraform state in S3 with encryption
- Use least privilege IAM policies
- Enable MFA on AWS accounts
- Rotate access keys regularly

## Cost Optimization Tips

### Development Environment
- Use `t3.micro` instances for RDS and ElastiCache
- Set `node_desired_size = 1` for minimal EKS nodes
- Enable `skip_final_snapshot = true` for RDS in dev
- Set shorter log retention periods

### Monitoring Costs
```bash
# Check current costs
aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31 --granularity MONTHLY --metrics BlendedCost

# List running instances
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name]'
```

## Emergency Procedures

### Infrastructure Issues
1. Check AWS service health dashboard
2. Review CloudTrail logs for recent changes
3. Check Terraform state for inconsistencies
4. Use manual AWS console for emergency fixes

### Access Recovery
1. Use root account if IAM issues
2. Check IAM policies and roles
3. Verify MFA settings
4. Reset access keys if needed

### Data Recovery
1. Check RDS automated backups
2. Restore from point-in-time if needed
3. Use ElastiCache backup if available
4. Recover from Terraform state backups

## Support Contacts

- AWS Support: Create case in AWS console
- Terraform Issues: Check HashiCorp documentation
- Kubernetes Issues: Check Kubernetes documentation
- Internal Issues: Create GitHub issue in repository

---

For detailed instructions, see the [Manual Setup Guide](manual-setup.md).