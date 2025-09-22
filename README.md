# Solidity Security AWS Infrastructure

This repository contains the AWS Infrastructure as Code (IaC) for the Solidity Security platform using Terraform. It provides a complete cloud-native infrastructure foundation for running security analysis tools and services on AWS.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS Cloud Infrastructure                  │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   Development   │  │     Staging     │  │   Production    │ │
│  │   Environment   │  │   Environment   │  │   Environment   │ │
│  │                 │  │                 │  │                 │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │ │
│  │ │     VPC     │ │  │ │     VPC     │ │  │ │     VPC     │ │ │
│  │ │   EKS       │ │  │ │   EKS       │ │  │ │   EKS       │ │ │
│  │ │   RDS       │ │  │ │   RDS       │ │  │ │   RDS       │ │ │
│  │ │ ElastiCache │ │  │ │ ElastiCache │ │  │ │ ElastiCache │ │ │
│  │ │   ECR       │ │  │ │   ECR       │ │  │ │   ECR       │ │ │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
                    ┌─────────────────────────┐
                    │     Cloudflare DNS      │
                    │ advancedblockchainsecurity.com │
                    └─────────────────────────┘
```

## 🚀 Features

- **Multi-Environment Support**: Dev, Staging, and Production environments
- **Container Registry**: ECR with vulnerability scanning and lifecycle policies
- **Kubernetes Platform**: EKS with managed node groups and IRSA
- **Database Services**: RDS PostgreSQL with Multi-AZ and automated backups
- **Caching Layer**: ElastiCache Redis with encryption and clustering
- **Secret Management**: AWS Secrets Manager with automatic rotation
- **Security**: Network security groups, encryption, and compliance scanning
- **Monitoring**: CloudWatch integration and cost monitoring
- **CI/CD**: GitHub Actions with automated deployment and security checks
- **CDN & Security**: Cloudflare Enterprise handles WAF, DDoS protection, SSL/TLS, and global CDN

## 📁 Repository Structure

```
solidity-security-aws-infrastructure/
├── terraform/
│   ├── environments/           # Environment-specific configurations
│   │   ├── dev/               # Development environment
│   │   ├── staging/           # Staging environment
│   │   └── production/        # Production environment
│   ├── modules/               # Reusable Terraform modules
│   │   ├── vpc/              # VPC and networking
│   │   ├── eks/              # EKS cluster
│   │   ├── rds/              # PostgreSQL database
│   │   ├── elasticache/      # Redis cache
│   │   ├── ecr/              # Container registry
│   │   ├── iam/              # IAM roles and policies
│   │   ├── security-groups/  # Network security
│   │   └── secrets-manager/  # Secret management
│   └── shared/               # Shared configurations
├── .github/workflows/        # CI/CD pipelines
├── scripts/                  # Utility scripts
├── cloudflare/              # DNS configuration guide
└── docs/                    # Documentation
```

## 🛠️ Prerequisites

### Required Tools

- [Terraform](https://www.terraform.io/downloads.html) >= 1.5
- [AWS CLI](https://aws.amazon.com/cli/) >= 2.0
- [kubectl](https://kubernetes.io/docs/tasks/tools/) >= 1.27
- [Git](https://git-scm.com/downloads)

### AWS Setup

1. **AWS Account**: Ensure you have access to an AWS account with appropriate permissions
2. **IAM User/Role**: Create an IAM user or role with the following policies:
   - `PowerUserAccess` (or custom policy with required permissions)
   - S3 access for Terraform state storage
   - DynamoDB access for state locking

### GitHub Secrets

Configure the following secrets in your GitHub repository:

```bash
# AWS credentials for GitHub Actions
AWS_ROLE_ARN                 # IAM role ARN for OIDC
AWS_ACCESS_KEY_ID           # Alternative to OIDC
AWS_SECRET_ACCESS_KEY       # Alternative to OIDC

# Optional integrations
INFRACOST_API_KEY           # For cost estimation
SLACK_WEBHOOK_URL           # For notifications
```

## 🚀 Quick Start

### Option 1: Automated Setup (Recommended)

#### 1. Clone the Repository

```bash
git clone https://github.com/your-org/solidity-security-aws-infrastructure.git
cd solidity-security-aws-infrastructure
```

#### 2. Configure AWS Credentials

```bash
aws configure
# or
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

#### 3. Setup Backend and Deploy

```bash
# Setup Terraform backend (S3 + DynamoDB)
./scripts/setup-backend.sh dev

# Deploy infrastructure
./scripts/deploy-env.sh dev us-east-1 apply
```

#### 4. Configure kubectl

```bash
aws eks update-kubeconfig --region us-east-1 --name solidity-security-dev
kubectl get nodes
```

#### 5. Configure DNS in Cloudflare

After deployment, configure DNS records in Cloudflare pointing to your AWS ALB. See [Cloudflare DNS Configuration](cloudflare/dns-configuration.md) for detailed instructions.

### Option 2: Manual Setup

If you prefer manual setup or the scripts don't work in your environment, follow the comprehensive [Manual Setup Guide](docs/manual-setup.md) which provides step-by-step instructions for:

- Manual AWS backend setup
- Manual Terraform deployment
- Manual DNS configuration
- Troubleshooting common issues
- Debug commands and verification steps

## 🔧 Configuration

### Environment Variables

Each environment can be customized via `terraform.tfvars`:

```hcl
# terraform/environments/dev/terraform.tfvars
project_name = "solidity-security"
environment  = "dev"
aws_region   = "us-east-1"

# Network
vpc_cidr = "10.0.0.0/16"

# EKS
node_instance_types = ["t3.medium"]
node_desired_size   = 2
node_min_size      = 1
node_max_size      = 5

# RDS
rds_instance_class = "db.t3.micro"
rds_allocated_storage = 20

# ElastiCache
elasticache_node_type = "cache.t3.micro"
```

## 🔐 Security Features

### Network Security

- **VPC**: Isolated virtual network with public/private subnets
- **Security Groups**: Restrictive firewall rules for each service
- **NAT Gateways**: Secure outbound internet access for private subnets
- **VPC Endpoints**: Secure communication with AWS services

### Encryption

- **EKS**: Secrets encryption with AWS KMS
- **RDS**: Encryption at rest with customer-managed keys
- **ElastiCache**: Encryption in transit and at rest
- **S3**: Bucket encryption for Terraform state
- **SSL/TLS**: Managed by Cloudflare Enterprise with automatic certificate provisioning

### Access Control

- **IAM Roles**: Least privilege access with IRSA (IAM Roles for Service Accounts)
- **RBAC**: Kubernetes role-based access control
- **Secrets Manager**: Centralized secret management with rotation

### Web Security & Performance

- **Cloudflare Enterprise**: WAF protection, DDoS mitigation, and global CDN
- **Zero Trust Network**: Cloudflare security policies and access controls
- **SSL/TLS Management**: Automatic certificate provisioning and renewal

## 📊 Monitoring and Observability

### CloudWatch Integration

- **EKS Metrics**: Container Insights for cluster monitoring
- **RDS Metrics**: Database performance monitoring
- **Application Logs**: Centralized logging with CloudWatch Logs

### Cost Monitoring

- **Infracost**: Automated cost estimation in CI/CD
- **Resource Tagging**: Comprehensive tagging for cost allocation

## 🔄 CI/CD Pipeline

### Automated Workflows

1. **Terraform Plan** (`terraform-plan.yml`)
   - Triggered on pull requests
   - Runs security scans and cost estimation
   - Posts plan results as PR comments

2. **Terraform Apply** (`terraform-apply.yml`)
   - Triggered on merge to main
   - Deploys to development automatically
   - Manual approval for staging/production

3. **Environment Destruction** (`destroy-env.yml`)
   - Manual workflow for environment cleanup
   - Creates backups before destruction
   - Requires explicit confirmation

## 💰 Cost Optimization

### Development Environment
- **Target Cost**: $320-400/month
- **Optimizations**:
  - t3.micro instances for RDS and ElastiCache
  - Minimal node count for EKS
  - Shortened log retention periods

### Production Scaling
- **Estimated Cost**: $1,400+/month
- **Features**:
  - Multi-AZ RDS with read replicas
  - ElastiCache clustering
  - Enhanced monitoring

## 🔧 Troubleshooting

### Common Issues

1. **Terraform State Lock**
   ```bash
   terraform force-unlock <lock-id>
   ```

2. **EKS Access Denied**
   ```bash
   aws eks update-kubeconfig --region us-east-1 --name solidity-security-dev
   ```

3. **RDS Connection Issues**
   - Check security group rules
   - Verify VPC configuration
   - Test from EKS pods

### Debug Commands

```bash
# Check EKS cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# Check AWS resources
aws eks describe-cluster --name solidity-security-dev
aws rds describe-db-instances
aws elasticache describe-replication-groups

# Terraform state
terraform show
terraform state list
```

## 📚 Documentation

### Setup Guides
- [Manual Setup Guide](docs/manual-setup.md) - Comprehensive step-by-step manual instructions
- [Cloudflare DNS Configuration](cloudflare/dns-configuration.md) - DNS setup for domain management

### Technical Documentation
- [Module Documentation](terraform/modules/) - Terraform module details
- [Security Guide](docs/security.md) - Security best practices
- [Cost Optimization](docs/cost-optimization.md) - Cost management strategies
- [Troubleshooting Guide](docs/troubleshooting.md) - Common issues and solutions

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes following conventions
4. Run security scans and tests
5. Submit a pull request

## 🔗 Related Repositories

- [solidity-security-platform](../solidity-security-platform) - Main application code
- [solidity-security-infrastructure](../solidity-security-infrastructure) - Kubernetes manifests
- [solidity-security-tools](../solidity-security-tools) - Security tool integrations
- [solidity-security-docs](../solidity-security-docs) - Documentation site

---

**Built with ❤️ for blockchain security**