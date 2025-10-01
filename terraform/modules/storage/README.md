# Storage Module - Task 1.3

This module provides database and caching infrastructure for the Solidity Security Platform, implementing PostgreSQL RDS and ElastiCache Redis services with comprehensive security, monitoring, and high availability features.

## Features

### PostgreSQL RDS
- **✅ Secure Database**: Encrypted storage and transit with KMS
- **✅ High Availability**: Multi-AZ deployment for production
- **✅ Read Replicas**: Optional read replicas for performance
- **✅ Automated Backups**: Configurable retention periods
- **✅ Performance Monitoring**: Enhanced monitoring and Performance Insights
- **✅ Security**: Network isolation, security groups, and secrets management
- **✅ Parameter Optimization**: Custom parameter groups for workload optimization

### ElastiCache Redis
- **✅ Secure Caching**: Encrypted at-rest and in-transit
- **✅ High Availability**: Multi-AZ with automatic failover
- **✅ Session Store**: Optional separate Redis cluster for sessions
- **✅ Monitoring**: CloudWatch logging and metrics
- **✅ Security**: Auth tokens managed via AWS Secrets Manager
- **✅ Performance**: Configurable node types and cluster sizes

### Security Features
- **✅ Encryption**: KMS encryption for all data at rest and in transit
- **✅ Secrets Management**: AWS Secrets Manager for credentials
- **✅ Network Security**: Private subnets with security groups
- **✅ Access Control**: IAM roles and policies
- **✅ Audit Logging**: CloudWatch logs for all database operations

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        VPC (from networking module)         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐              ┌─────────────────┐      │
│  │  Database       │              │  ElastiCache    │      │
│  │  Subnet Group   │              │  Subnet Group   │      │
│  │                 │              │                 │      │
│  │  ┌───────────┐  │              │  ┌───────────┐  │      │
│  │  │PostgreSQL │  │              │  │   Redis   │  │      │
│  │  │    RDS    │  │              │  │ Cluster   │  │      │
│  │  │           │  │              │  │           │  │      │
│  │  │ Multi-AZ  │  │              │  │ Multi-AZ  │  │      │
│  │  └───────────┘  │              │  └───────────┘  │      │
│  │                 │              │                 │      │
│  │  ┌───────────┐  │              │  ┌───────────┐  │      │
│  │  │   Read    │  │              │  │ Sessions  │  │      │
│  │  │  Replica  │  │              │  │   Redis   │  │      │
│  │  │(optional) │  │              │  │(optional) │  │      │
│  │  └───────────┘  │              │  └───────────┘  │      │
│  └─────────────────┘              └─────────────────┘      │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                    AWS Secrets Manager                     │
│              ┌─────────────┐  ┌─────────────┐              │
│              │  PostgreSQL │  │    Redis    │              │
│              │ Credentials │  │ Auth Tokens │              │
│              └─────────────┘  └─────────────┘              │
└─────────────────────────────────────────────────────────────┘
```

## Usage

### Basic Usage

```hcl
module "storage" {
  source = "./modules/storage"

  project     = "solidity-security"
  environment = "staging"

  # Network configuration from networking module
  db_subnet_group_name          = module.networking.db_subnet_group_name
  elasticache_subnet_ids        = module.networking.database_subnet_ids
  postgresql_security_group_ids = [module.networking.postgresql_security_group_id]
  redis_security_group_ids      = [module.networking.elasticache_security_group_id]

  # PostgreSQL configuration
  postgresql_instance_class    = "db.t3.micro"
  postgresql_allocated_storage = 20

  # Redis configuration
  redis_node_type         = "cache.t3.micro"
  redis_num_cache_clusters = 1

  tags = {
    Environment = "staging"
  }
}
```

### Production Configuration

```hcl
module "storage" {
  source = "./modules/storage"

  project     = "solidity-security"
  environment = "production"

  # Network configuration
  db_subnet_group_name          = module.networking.db_subnet_group_name
  elasticache_subnet_ids        = module.networking.database_subnet_ids
  postgresql_security_group_ids = [module.networking.postgresql_security_group_id]
  redis_security_group_ids      = [module.networking.elasticache_security_group_id]

  # PostgreSQL - production optimized
  postgresql_instance_class       = "db.r6g.large"
  postgresql_allocated_storage    = 100
  postgresql_multi_az            = true
  create_read_replica            = true

  # Redis - production optimized
  redis_node_type                = "cache.r6g.large"
  redis_num_cache_clusters       = 3
  redis_automatic_failover_enabled = true
  redis_multi_az_enabled         = true

  # Session store
  create_session_store = true

  # Enhanced monitoring
  enable_enhanced_monitoring  = true
  enable_performance_insights = true

  tags = {
    Environment = "production"
  }
}
```

## Configuration Options

### Environment-Specific Defaults

#### Staging Environment
- **PostgreSQL**: `db.t3.micro`, single-AZ, minimal storage
- **Redis**: `cache.t3.micro`, single node
- **Monitoring**: Basic CloudWatch logs
- **Backups**: 3-day retention
- **Cost**: ~$30-50/month

#### Production Environment
- **PostgreSQL**: `db.r6g.large`, Multi-AZ, read replica
- **Redis**: `cache.r6g.large`, Multi-AZ with failover
- **Monitoring**: Enhanced monitoring, Performance Insights
- **Backups**: 30-day retention
- **Cost**: ~$400-600/month

## Security

### Encryption
- **At Rest**: KMS encryption for RDS and ElastiCache
- **In Transit**: TLS/SSL encryption for all connections
- **Keys**: Customer-managed KMS keys with proper rotation

### Access Control
- **Network**: Private subnets with security groups
- **Authentication**: Strong passwords via Secrets Manager
- **Authorization**: IAM roles with least privilege

### Monitoring
- **Database Logs**: PostgreSQL query and error logs
- **Cache Logs**: Redis slow log monitoring
- **Metrics**: CloudWatch metrics for performance monitoring
- **Alerts**: Configurable CloudWatch alarms

## Outputs

### Connection Information
- PostgreSQL endpoint and port
- Redis primary and reader endpoints
- Secrets Manager ARNs for credentials

### Resource Identifiers
- RDS instance IDs and ARNs
- ElastiCache replication group IDs
- KMS key ARNs

## Integration

This module integrates with:
- **Networking Module**: Uses VPC, subnets, and security groups
- **EKS Module**: Provides database connectivity for applications
- **Monitoring Module**: Exports metrics to CloudWatch

## Cost Optimization

### Staging Optimizations
1. **Single-AZ Deployment**: Reduces RDS and ElastiCache costs
2. **Smaller Instance Types**: Cost-effective for development
3. **Shorter Retention**: Reduced backup and log storage costs
4. **No Read Replicas**: Eliminates additional instance costs

### Production Optimizations
1. **Reserved Instances**: 1-3 year terms for predictable workloads
2. **Performance Monitoring**: Optimize instance sizes based on metrics
3. **Storage Auto-scaling**: Automatic storage expansion
4. **Backup Lifecycle**: Automated cleanup of old snapshots

## Deployment

### Prerequisites
1. Networking module deployed
2. S3 backend configured
3. Appropriate IAM permissions

### Deployment Steps

```bash
# Initialize Terraform
terraform init -backend-config=backend.tfvars

# Plan deployment
terraform plan -var-file=terraform.tfvars

# Apply changes
terraform apply -var-file=terraform.tfvars
```

### Environment-Specific Commands

```bash
# Staging
cd environments/staging/storage
terraform init -backend-config=backend.tfvars
terraform apply -var-file=terraform.tfvars

# Production
cd environments/production/storage
terraform init -backend-config=backend.tfvars
terraform apply -var-file=terraform.tfvars
```

## Monitoring and Maintenance

### Key Metrics to Monitor
- **RDS**: CPU, memory, storage, connections
- **ElastiCache**: CPU, memory, cache hit ratio
- **Security**: Failed authentication attempts

### Maintenance Tasks
- **Security Updates**: Automatic minor version upgrades
- **Backups**: Automated daily backups
- **Monitoring**: CloudWatch dashboards and alarms
- **Performance**: Regular Performance Insights review

## Troubleshooting

### Common Issues
1. **Connection Timeouts**: Check security groups and NACLs
2. **Performance Issues**: Review Performance Insights
3. **Storage Full**: Monitor auto-scaling settings
4. **Backup Failures**: Check IAM permissions

### Useful Commands

```bash
# Check RDS status
aws rds describe-db-instances --region us-west-2

# Check ElastiCache status
aws elasticache describe-replication-groups --region us-west-2

# View secrets
aws secretsmanager list-secrets --region us-west-2

# Check logs
aws logs describe-log-groups --region us-west-2
```

## Future Enhancements

1. **Database Migration**: DMS integration for data migration
2. **Read Replicas**: Cross-region read replicas
3. **Monitoring**: Custom CloudWatch dashboards
4. **Backup Strategies**: Cross-region backup replication
5. **Performance**: Query performance optimization