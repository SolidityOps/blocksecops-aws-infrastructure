# VPC Module

This module creates a VPC with public and private subnets across multiple availability zones, along with necessary networking components for a secure Kubernetes deployment.

## Features

- VPC with customizable CIDR block
- Public subnets with Internet Gateway access
- Private subnets with NAT Gateway access
- Database subnets for RDS and ElastiCache
- Proper subnet tagging for EKS and load balancer discovery
- DB and ElastiCache subnet groups

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                           VPC                               │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │    AZ-1      │  │    AZ-2      │  │    AZ-3      │      │
│  │              │  │              │  │              │      │
│  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │      │
│  │ │ Public   │ │  │ │ Public   │ │  │ │ Public   │ │      │
│  │ │ Subnet   │ │  │ │ Subnet   │ │  │ │ Subnet   │ │      │
│  │ └────┬─────┘ │  │ └────┬─────┘ │  │ └────┬─────┘ │      │
│  │      │       │  │      │       │  │      │       │      │
│  │   ┌──▼──┐    │  │   ┌──▼──┐    │  │   ┌──▼──┐    │      │
│  │   │ NAT │    │  │   │ NAT │    │  │   │ NAT │    │      │
│  │   │ GW  │    │  │   │ GW  │    │  │   │ GW  │    │      │
│  │   └──┬──┘    │  │   └──┬──┘    │  │   └──┬──┘    │      │
│  │      │       │  │      │       │  │      │       │      │
│  │ ┌────▼─────┐ │  │ ┌────▼─────┐ │  │ ┌────▼─────┐ │      │
│  │ │ Private  │ │  │ │ Private  │ │  │ │ Private  │ │      │
│  │ │ Subnet   │ │  │ │ Subnet   │ │  │ │ Subnet   │ │      │
│  │ └──────────┘ │  │ └──────────┘ │  │ └──────────┘ │      │
│  │              │  │              │  │              │      │
│  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │      │
│  │ │ Database │ │  │ │ Database │ │  │ │ Database │ │      │
│  │ │ Subnet   │ │  │ │ Subnet   │ │  │ │ Subnet   │ │      │
│  │ └──────────┘ │  │ └──────────┘ │  │ └──────────┘ │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

## Usage

```hcl
module "vpc" {
  source = "./modules/vpc"

  project_name = "solidity-security"
  environment  = "dev"
  vpc_cidr     = "10.0.0.0/16"

  public_subnet_count   = 3
  private_subnet_count  = 3
  database_subnet_count = 3
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_name | Name of the project | `string` | `"solidity-security"` | no |
| environment | Environment name (dev, staging, production) | `string` | n/a | yes |
| vpc_cidr | CIDR block for VPC | `string` | `"10.0.0.0/16"` | no |
| public_subnet_count | Number of public subnets | `number` | `3` | no |
| private_subnet_count | Number of private subnets | `number` | `3` | no |
| database_subnet_count | Number of database subnets | `number` | `3` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| vpc_cidr | CIDR block of the VPC |
| public_subnet_ids | IDs of the public subnets |
| private_subnet_ids | IDs of the private subnets |
| database_subnet_ids | IDs of the database subnets |
| db_subnet_group_name | Name of the DB subnet group |
| elasticache_subnet_group_name | Name of the ElastiCache subnet group |
| nat_gateway_ips | Elastic IP addresses of NAT Gateways |

## Security Features

- Private subnets for application workloads
- Isolated database subnets
- NAT Gateways for outbound internet access from private subnets
- Proper subnet tagging for Kubernetes load balancer discovery
- Network ACLs for additional security (configurable)