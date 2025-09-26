# Solidity Security Platform - AWS Infrastructure

This repository contains Terraform code for deploying the AWS infrastructure for the Solidity Security Platform. The infrastructure is designed for single-AZ deployment to optimize costs for MVP launch.

## Architecture Overview

### Network Design
- **VPC**: /16 CIDR block with single availability zone deployment
- **Public Subnet**: Contains Application Load Balancer and NAT Gateway
- **Private Subnet**: Contains EKS nodes and ElastiCache cluster
- **Security Groups**: Least-privilege access controls for all services

### Infrastructure Components
- **VPC & Networking**: Secure network foundation with NAT gateway and VPC endpoints
- **Security Groups**: Service-specific security groups for EKS, ElastiCache, and ALB
- **VPC Endpoints**: Cost optimization through S3, ECR, and Secrets Manager endpoints
- **Monitoring**: VPC Flow Logs for network security analysis

## Directory Structure

```
terraform/
├── modules/
│   ├── networking/            # VPC, subnets, security groups, VPC endpoints
│   └── monitoring/            # VPC Flow Logs configuration
├── environments/
│   ├── staging/               # Staging environment configuration
│   └── production/            # Production environment configuration
└── shared/                    # Shared infrastructure components
```

> **Note**: PostgreSQL database infrastructure is deployed as StatefulSets in Kubernetes rather than RDS, providing significant cost savings (~$1200+/month) and better integration with the containerized architecture. PostgreSQL manifests are managed in the `solidity-security-monitoring` repository.

## Environment Configuration

### Staging
- **VPC CIDR**: 10.0.0.0/16
- **Log Retention**: 7 days (cost optimization)
- **Purpose**: Development and testing

### Production
- **VPC CIDR**: 10.1.0.0/16
- **Log Retention**: 90 days (compliance)
- **Purpose**: Production workloads

## Security Features

### Network Security
- Private subnets for all application infrastructure
- Security groups with least-privilege access
- VPC endpoints to reduce internet egress
- VPC Flow Logs for security monitoring

### Access Controls
- **EKS**: Cluster and node security groups with pod-to-pod communication
- **PostgreSQL**: Database runs as StatefulSets in Kubernetes with NetworkPolicies
- **ElastiCache**: Redis access restricted to application services
- **ALB**: Internet-facing with HTTPS/HTTP ingress

## Cost Optimization

### Single-AZ Deployment
- **PostgreSQL**: StatefulSets in Kubernetes (~$1200+/month savings vs RDS)
- **NAT Gateway**: Single gateway instead of per-AZ deployment
- **EKS**: Simplified node management in single AZ

### VPC Endpoints
- S3, ECR, Secrets Manager endpoints
- Reduces NAT gateway data transfer costs
- Improves security by keeping traffic within AWS network

## Deployment Instructions

### Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform >= 1.0 installed
- Appropriate IAM permissions for resource creation

### Staging Deployment
```bash
cd terraform/environments/staging
terraform init
terraform plan
terraform apply
```

### Production Deployment
```bash
cd terraform/environments/production
terraform init
terraform plan
terraform apply
```

## Network Configuration

### CIDR Allocation
- **Staging VPC**: 10.0.0.0/16
  - Public: 10.0.1.0/24
  - Private: 10.0.2.0/24
- **Production VPC**: 10.1.0.0/16
  - Public: 10.1.1.0/24
  - Private: 10.1.2.0/24

### Security Group Rules
- **ALB**: Ports 80/443 from internet
- **EKS Nodes**: Pod communication, ALB health checks
- **PostgreSQL**: Access controlled via Kubernetes NetworkPolicies
- **ElastiCache**: Port 6379 from EKS nodes only

## Monitoring and Logging

### VPC Flow Logs
- Captures all network traffic metadata
- Stored in S3 for cost-effective long-term retention
- Configurable retention periods per environment
- Used for security analysis and troubleshooting

## Future Scaling

### Multi-AZ Migration
When ready to scale beyond MVP:
1. Add additional subnets in other AZs
2. Scale PostgreSQL with multiple replicas in Kubernetes
3. Deploy additional NAT gateways for redundancy
4. Update EKS node groups for multi-AZ distribution

### Cost Monitoring
- Use AWS Cost Explorer to track infrastructure costs
- Set up billing alerts for budget management
- Review VPC endpoint usage for optimization opportunities

## Support

For infrastructure issues or questions:
- Review S3 bucket for VPC Flow Logs analysis
- Check Terraform state for resource configuration
- Use AWS Console for real-time resource monitoring