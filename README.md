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
- **ElastiCache Redis**: Managed Redis clusters for session storage and caching
- **Security Groups**: Service-specific security groups for EKS, ElastiCache, and ALB
- **VPC Endpoints**: Cost optimization through S3 and ECR endpoints
- **Monitoring**: VPC Flow Logs and ElastiCache monitoring with CloudWatch

## Directory Structure

```
terraform/
├── modules/
│   ├── networking/            # VPC, subnets, security groups, VPC endpoints
│   ├── storage/              # ElastiCache Redis configuration
│   └── monitoring/           # VPC Flow Logs and cache monitoring
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
- **Redis Instance**: cache.t3.micro (single node)
- **Purpose**: Development and testing

### Production
- **VPC CIDR**: 10.1.0.0/16
- **Log Retention**: 90 days (compliance)
- **Redis Instance**: cache.t3.small (single node, MVP)
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
- **ElastiCache**: Redis access restricted to EKS nodes only with AUTH token
- **ALB**: Internet-facing with HTTPS/HTTP ingress
- **Secrets Management**: Redis AUTH tokens stored in HashiCorp Vault

## Cost Optimization

### Single-AZ Deployment
- **PostgreSQL**: StatefulSets in Kubernetes (~$1200+/month savings vs RDS)
- **ElastiCache**: Single-node Redis clusters for MVP phase
- **NAT Gateway**: Single gateway instead of per-AZ deployment
- **EKS**: Simplified node management in single AZ

### VPC Endpoints
- S3, ECR endpoints
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
- **ElastiCache**: Port 6379 from EKS nodes only with AUTH token authentication

## Monitoring and Logging

### VPC Flow Logs
- Captures all network traffic metadata
- Stored in S3 for cost-effective long-term retention
- Configurable retention periods per environment
- Used for security analysis and troubleshooting

### ElastiCache Monitoring
- CloudWatch metrics for CPU, memory, and connection monitoring
- Cache hit rate monitoring and alerting
- Redis slow log monitoring
- Environment-specific CloudWatch dashboards
- Automated alerting for performance thresholds

## Future Scaling

### Multi-AZ Migration
When ready to scale beyond MVP:
1. Add additional subnets in other AZs
2. Scale PostgreSQL with multiple replicas in Kubernetes
3. Migrate to Redis Cluster mode for ElastiCache
4. Deploy additional NAT gateways for redundancy
5. Update EKS node groups for multi-AZ distribution

### Cost Monitoring
- Use AWS Cost Explorer to track infrastructure costs
- Set up billing alerts for budget management
- Review VPC endpoint usage for optimization opportunities

## ElastiCache Redis Usage

### Connection Information
Redis clusters are accessible from EKS nodes using:
- **Staging**: `staging-redis.cluster-id.cache.amazonaws.com:6379`
- **Production**: `production-redis.cluster-id.cache.amazonaws.com:6379`

### Authentication
- AUTH tokens are stored in HashiCorp Vault
- Use Vault Secrets Operator in Kubernetes to inject credentials
- All connections require AUTH token authentication

### Monitoring
- Access CloudWatch dashboards via Terraform outputs
- Monitor cache hit rates, CPU, memory, and connections
- Set up alerts for performance thresholds

## Support

For infrastructure issues or questions:
- Review S3 bucket for VPC Flow Logs analysis
- Check Terraform state for resource configuration
- Use AWS Console for real-time resource monitoring
- Review ElastiCache CloudWatch dashboards for cache performance