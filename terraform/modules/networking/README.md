# Networking Module

This module creates a secure VPC infrastructure for the Solidity Security Platform, providing the networking foundation for EKS clusters, PostgreSQL StatefulSets, and ElastiCache services.

## Features

- **VPC with Public and Private Subnets**: Multi-tier architecture with isolated subnets
- **Single-AZ Deployment**: Cost-optimized for MVP deployment
- **Security Groups**: Least-privilege access for EKS, databases, and load balancers
- **NAT Gateway/Instance**: Secure internet access for private subnets
- **VPC Endpoints**: AWS service access without internet routing
- **Network Monitoring**: VPC Flow Logs and CloudWatch integration
- **Network ACLs**: Additional security layer for subnet isolation

## Architecture

```
Internet Gateway
       |
   Public Subnet (ALB, NAT Gateway)
       |
   Private Subnet (EKS Nodes, Apps)
       |
   Database Subnet (PostgreSQL, Redis)
```

## Usage

### Basic Usage

```hcl
module "networking" {
  source = "./modules/networking"

  project     = "solidity-security"
  environment = "staging"
  vpc_cidr    = "10.0.0.0/16"

  # MVP single-AZ deployment
  single_az_deployment = true

  # Enable NAT gateway for private subnet internet access
  enable_nat_gateway = true

  # Create VPC endpoints for cost optimization
  create_vpc_endpoints = true

  tags = {
    Owner       = "devops-team"
    Environment = "staging"
  }
}
```

### Production Configuration

```hcl
module "networking" {
  source = "./modules/networking"

  project     = "solidity-security"
  environment = "production"
  vpc_cidr    = "10.1.0.0/16"

  # Multi-AZ for high availability
  single_az_deployment = false
  max_azs              = 3

  # Production features
  enable_nat_gateway       = true
  create_vpc_endpoints     = true
  enable_vpc_flow_logs     = true
  create_network_acls      = true

  # Security
  create_eks_security_groups      = true
  create_database_security_groups = true
  create_alb_security_group      = true

  tags = {
    Owner       = "devops-team"
    Environment = "production"
    Compliance  = "required"
  }
}
```

### Cost-Optimized Configuration

```hcl
module "networking" {
  source = "./modules/networking"

  project     = "solidity-security"
  environment = "staging"
  vpc_cidr    = "10.0.0.0/16"

  # Cost optimizations
  single_az_deployment = true
  use_nat_instance     = true
  enable_nat_gateway   = false

  # Minimal VPC endpoints
  create_vpc_endpoints = false

  tags = {
    CostOptimized = "true"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project | Project name used for resource naming | `string` | `"solidity-security"` | no |
| environment | Environment name (staging, production) | `string` | n/a | yes |
| vpc_cidr | CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| single_az_deployment | Whether to deploy in single AZ for cost optimization | `bool` | `true` | no |
| enable_nat_gateway | Whether to create NAT gateways for private subnet internet access | `bool` | `true` | no |
| use_nat_instance | Use NAT instance instead of NAT gateway for cost savings | `bool` | `false` | no |
| create_database_subnets | Whether to create separate database subnets | `bool` | `true` | no |
| create_vpc_endpoints | Whether to create VPC endpoints for AWS services | `bool` | `true` | no |
| enable_vpc_flow_logs | Whether to enable VPC Flow Logs | `bool` | `true` | no |
| tags | Additional tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| vpc_cidr_block | CIDR block of the VPC |
| public_subnet_ids | IDs of the public subnets |
| private_subnet_ids | IDs of the private subnets |
| database_subnet_ids | IDs of the database subnets |
| eks_cluster_security_group_id | ID of the EKS cluster security group |
| eks_nodes_security_group_id | ID of the EKS nodes security group |
| alb_security_group_id | ID of the ALB security group |
| postgresql_security_group_id | ID of the PostgreSQL security group |
| elasticache_security_group_id | ID of the ElastiCache security group |
| nat_gateway_ids | IDs of the NAT gateways |
| db_subnet_group_name | Name of the database subnet group |
| elasticache_subnet_group_name | Name of the ElastiCache subnet group |

## Security Groups

### EKS Cluster Security Group
- **Inbound**: HTTPS (443) from VPC
- **Outbound**: All traffic

### EKS Nodes Security Group
- **Inbound**:
  - Node-to-node communication (all ports)
  - HTTPS from cluster (443)
  - Kubelet API (10250)
  - NodePort services (30000-32767)
- **Outbound**: All traffic

### Application Load Balancer Security Group
- **Inbound**: HTTP (80), HTTPS (443) from internet
- **Outbound**: All traffic to VPC

### PostgreSQL Security Group
- **Inbound**: PostgreSQL (5432) from EKS nodes and private subnets
- **Outbound**: None (database should not initiate connections)

### ElastiCache Security Group
- **Inbound**: Redis (6379) from EKS nodes and private subnets
- **Outbound**: None

### VPC Endpoints Security Group
- **Inbound**: HTTPS (443), DNS (53) from VPC
- **Outbound**: All traffic

## VPC Endpoints

The module creates the following VPC endpoints to reduce internet egress costs:

### Gateway Endpoints (No Cost)
- **S3**: Object storage access
- **DynamoDB**: NoSQL database access

### Interface Endpoints
- **ECR API**: Container registry authentication
- **ECR DKR**: Container image pulls
- **CloudWatch Logs**: Log shipping
- **CloudWatch Monitoring**: Metrics publishing
- **Secrets Manager**: Secret retrieval
- **Systems Manager**: Parameter access
- **EKS**: Cluster API access
- **EC2**: Instance metadata and API

## Network ACLs

Additional security layer with stateless rules:

### Public Subnet NACL
- **Inbound**: HTTP/HTTPS from internet, SSH from VPC, ephemeral ports
- **Outbound**: All traffic

### Private Subnet NACL
- **Inbound**: All traffic from VPC, ephemeral ports from internet
- **Outbound**: All traffic

### Database Subnet NACL
- **Inbound**: Database ports from private subnets only
- **Outbound**: HTTP/HTTPS for updates only

## Cost Optimization

### NAT Instance vs NAT Gateway
- **NAT Gateway**: $45/month + data processing costs (recommended for production)
- **NAT Instance**: EC2 instance costs only (~$5-15/month for t3.nano)

### VPC Endpoints
- **Interface Endpoints**: $7.20/month each + data processing
- **Gateway Endpoints**: Free (S3, DynamoDB)
- **Savings**: Reduces NAT gateway data processing costs

### Single-AZ Deployment
- **Staging**: Single AZ reduces NAT and endpoint costs by 2/3
- **Production**: Multi-AZ for high availability

## Monitoring

### VPC Flow Logs
- **Destination**: CloudWatch Logs
- **Retention**: 14 days (configurable)
- **Traffic**: All (accepted and rejected)

### CloudWatch Metrics
- **NAT Instance**: CPU, memory, disk, network
- **VPC**: Flow log metrics

## Security Features

- **Least Privilege**: Security groups with minimal required access
- **Defense in Depth**: Security groups + NACLs + VPC isolation
- **Private by Default**: Databases in isolated subnets
- **Encrypted Transit**: VPC endpoints use TLS
- **Flow Logging**: All network traffic logged for analysis

## Integration with Other Modules

### EKS Module
```hcl
module "eks" {
  source = "./modules/eks"

  vpc_id                        = module.networking.vpc_id
  private_subnet_ids           = module.networking.private_subnet_ids
  eks_cluster_security_group_id = module.networking.eks_cluster_security_group_id
  eks_nodes_security_group_id  = module.networking.eks_nodes_security_group_id
}
```

### Database Module
```hcl
module "postgresql" {
  source = "./modules/database"

  vpc_id                 = module.networking.vpc_id
  db_subnet_group_name   = module.networking.db_subnet_group_name
  security_group_ids     = [module.networking.postgresql_security_group_id]
}
```

## Examples

See the `examples/` directory for complete deployment examples:
- `examples/staging/` - Single-AZ cost-optimized deployment
- `examples/production/` - Multi-AZ high-availability deployment

## Requirements

- Terraform >= 1.5
- AWS Provider ~> 5.0
- AWS CLI configured with appropriate permissions

## Limitations

- Maximum 6 availability zones supported
- Database subnets require at least 2 AZs for RDS
- VPC endpoints only available in supported regions

## Contributing

1. Update variables in `variables.tf`
2. Update outputs in `outputs.tf`
3. Update this README
4. Run `terraform fmt` and `terraform validate`
5. Test with multiple configurations