# Terraform Infrastructure for BlockSecOps Platform

This repository contains Terraform Infrastructure as Code (IaC) for the BlockSecOps Platform AWS infrastructure, following the architecture templates and implementing Task 1.2 networking requirements.

## Architecture Overview

The infrastructure is organized using a modular approach with separate environments for staging and production:

```
terraform/
├── modules/
│   └── networking/          # VPC, subnets, security groups, NAT, VPC endpoints
├── environments/
│   ├── staging/            # Single-AZ cost-optimized deployment
│   └── production/         # Multi-AZ high-availability deployment
└── README.md
```

## Networking Module (Task 1.2)

### Features Implemented

- **✅ VPC with Public and Private Subnets**: Multi-tier architecture with isolated subnets
- **✅ Single-AZ Deployment**: Cost-optimized MVP deployment for staging
- **✅ Multi-AZ Support**: High-availability production deployment
- **✅ Security Groups**: Least-privilege access for EKS, databases, and load balancers
- **✅ NAT Gateway/Instance**: Secure internet access for private subnets
- **✅ VPC Endpoints**: AWS service access without internet routing
- **✅ Network Monitoring**: VPC Flow Logs and CloudWatch integration
- **✅ Network ACLs**: Additional security layer for subnet isolation

### Architecture Diagram

```
┌─────────────────┐
│ Internet Gateway │
└─────────┬───────┘
          │
┌─────────▼───────┐
│  Public Subnet  │  ALB, NAT Gateway/Instance
│   10.x.0.0/24   │
└─────────┬───────┘
          │
┌─────────▼───────┐
│ Private Subnet  │  EKS Nodes, Application Services
│   10.x.1.0/24   │
└─────────┬───────┘
          │
┌─────────▼───────┐
│Database Subnet  │  PostgreSQL StatefulSets, ElastiCache
│   10.x.2.0/24   │
└─────────────────┘
```

## Quick Start

### Prerequisites

1. **Terraform**: >= 1.5
2. **AWS CLI**: Configured with appropriate permissions
3. **Backend Resources**: S3 bucket and DynamoDB table for state management

### 1. Create Backend Resources

First, create the S3 bucket and DynamoDB table for Terraform state:

```bash
# Create S3 bucket for state storage
aws s3 mb s3://blocksecops-terraform-state --region us-west-2

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket blocksecops-terraform-state \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name blocksecops-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-west-2
```

### 2. Deploy Staging Environment

```bash
# Navigate to staging networking
cd environments/staging/networking

# Initialize Terraform
terraform init -backend-config=backend.tfvars

# Plan deployment
terraform plan -var-file=terraform.tfvars

# Apply changes
terraform apply -var-file=terraform.tfvars
```

### 3. Deploy Production Environment

```bash
# Navigate to production networking
cd environments/production/networking

# Initialize Terraform
terraform init -backend-config=backend.tfvars

# Plan deployment
terraform plan -var-file=terraform.tfvars

# Apply changes
terraform apply -var-file=terraform.tfvars
```

## Environment Configurations

### Staging Environment

**Optimized for cost and development:**

- **Region**: us-west-2
- **VPC CIDR**: 10.0.0.0/16
- **Deployment**: Single-AZ (us-west-2a)
- **NAT**: NAT Instance (t3.nano) for cost savings
- **VPC Endpoints**: Disabled to reduce costs
- **Monitoring**: Basic VPC Flow Logs (7-day retention)
- **Target Use Cases**: Development, testing, demo environments

**Cost Estimate**: ~$15-25/month

### Production Environment

**Optimized for high availability and performance:**

- **Region**: us-west-2
- **VPC CIDR**: 10.1.0.0/16
- **Deployment**: Multi-AZ (us-west-2a, us-west-2b, us-west-2c)
- **NAT**: NAT Gateways for reliability
- **VPC Endpoints**: Full suite for cost optimization
- **Monitoring**: Enhanced VPC Flow Logs (30-day retention)
- **Security**: Network ACLs, bastion host support
- **Target Use Cases**: Production workloads, customer-facing services

**Cost Estimate**: ~$200-300/month

## Security Features

### Network Security

- **Security Groups**: Least-privilege access with specific port/protocol restrictions
- **Network ACLs**: Stateless firewall rules for additional protection
- **Private Subnets**: Application workloads isolated from internet
- **Database Isolation**: Separate subnet tier for database services

### Access Control

- **EKS Security Groups**: Cluster and node communication
- **Database Security Groups**: PostgreSQL and ElastiCache access
- **ALB Security Group**: Load balancer internet access
- **Bastion Security Group**: Administrative access (production only)

### Monitoring & Compliance

- **VPC Flow Logs**: All network traffic logging
- **CloudWatch Integration**: Centralized monitoring
- **Encryption**: All logs encrypted at rest
- **Tagging Strategy**: Comprehensive resource tagging for compliance

## Cost Optimization

### Staging Optimizations

1. **NAT Instance**: $4-8/month vs $45/month for NAT Gateway
2. **Single-AZ**: 1/3 the NAT and endpoint costs
3. **Minimal VPC Endpoints**: Reduce interface endpoint costs
4. **Short Log Retention**: 7 days vs 30 days for production

### Production Optimizations

1. **VPC Endpoints**: Reduce NAT Gateway data processing costs
2. **Gateway Endpoints**: Free S3 and DynamoDB access
3. **Right-sized NAT Gateways**: Per-AZ for availability
4. **Reserved Instances**: Consider for long-term workloads

## Deployment Commands

### Initialize Environment

```bash
# Staging
cd environments/staging/networking
terraform init -backend-config=backend.tfvars

# Production
cd environments/production/networking
terraform init -backend-config=backend.tfvars
```

### Plan Changes

```bash
terraform plan -var-file=terraform.tfvars -out=tfplan
```

### Apply Changes

```bash
terraform apply tfplan
```

### Destroy Environment

```bash
terraform destroy -var-file=terraform.tfvars
```

## Module Outputs

Key outputs available for integration with other modules:

### Network Information
- `vpc_id` - VPC identifier
- `public_subnet_ids` - Public subnet identifiers
- `private_subnet_ids` - Private subnet identifiers
- `database_subnet_ids` - Database subnet identifiers

### Security Groups
- `eks_cluster_security_group_id` - EKS cluster security group
- `eks_nodes_security_group_id` - EKS worker nodes security group
- `alb_security_group_id` - Application Load Balancer security group
- `postgresql_security_group_id` - PostgreSQL database security group
- `elasticache_security_group_id` - ElastiCache security group

### Database Resources
- `db_subnet_group_name` - RDS subnet group
- `elasticache_subnet_group_name` - ElastiCache subnet group

## Integration with Future Modules

### EKS Cluster Module

```hcl
module "eks" {
  source = "../modules/eks"

  vpc_id                        = module.networking.vpc_id
  private_subnet_ids           = module.networking.private_subnet_ids
  eks_cluster_security_group_id = module.networking.eks_cluster_security_group_id
  eks_nodes_security_group_id  = module.networking.eks_nodes_security_group_id
}
```

### Database Module

```hcl
module "postgresql" {
  source = "../modules/database"

  vpc_id               = module.networking.vpc_id
  db_subnet_group_name = module.networking.db_subnet_group_name
  security_group_ids   = [module.networking.postgresql_security_group_id]
}
```

## Troubleshooting

### Common Issues

1. **Backend Access**: Ensure AWS credentials have S3 and DynamoDB permissions
2. **Region Mismatch**: Verify backend and provider regions match
3. **CIDR Conflicts**: Ensure staging (10.0.x.x) and production (10.1.x.x) don't overlap
4. **AZ Availability**: Some instance types may not be available in all AZs

### Validation Commands

```bash
# Validate Terraform configuration
terraform validate

# Check formatting
terraform fmt -check -recursive

# Plan without applying
terraform plan -detailed-exitcode
```

### State Management

```bash
# List resources in state
terraform state list

# Show specific resource
terraform state show module.networking.aws_vpc.main

# Import existing resource
terraform import module.networking.aws_vpc.main vpc-xxxxxxxxx
```

## Security Considerations

### Secrets Management

- **Never commit**: terraform.tfvars with sensitive values
- **Use**: AWS Secrets Manager or Parameter Store for secrets
- **Backend**: Encrypt S3 backend and enable MFA delete for production
- **Access**: Use IAM roles instead of access keys

### Network Security

- **Principle of Least Privilege**: Security groups allow only required ports
- **Defense in Depth**: Security groups + NACLs + private subnets
- **Monitoring**: VPC Flow Logs enabled for security analysis
- **Compliance**: All resources tagged for audit trails

## Support

For issues with this infrastructure:

1. **Terraform Issues**: Check `terraform validate` and logs
2. **AWS Permissions**: Verify IAM permissions for resources
3. **Network Connectivity**: Check VPC Flow Logs and security groups
4. **Cost Optimization**: Review AWS Cost Explorer and billing alerts

## Contributing

1. Follow the established module structure
2. Update documentation for new features
3. Test in staging before production deployment
4. Follow semantic versioning for module releases

## License

This infrastructure code is proprietary to the BlockSecOps Platform project.