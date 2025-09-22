# Services and Architecture Documentation

This document provides a comprehensive overview of all AWS services, third-party tools, and external vendors used in the Solidity Security AWS Infrastructure.

## 🏗️ AWS Services

### Core Compute and Container Services

#### Amazon Elastic Kubernetes Service (EKS)
- **Purpose**: Managed Kubernetes control plane for container orchestration
- **Configuration**:
  - EKS cluster with OIDC provider for IRSA (IAM Roles for Service Accounts)
  - Managed node groups with auto-scaling
  - EKS addons: VPC CNI, CoreDNS, kube-proxy, EBS CSI driver
- **Security**: Private API endpoint, CloudWatch logging enabled
- **Cost Optimization**: t3.medium instances in dev, scalable to larger instances in production

#### Amazon Elastic Container Registry (ECR)
- **Purpose**: Container image registry with vulnerability scanning
- **Features**:
  - Vulnerability scanning on image push
  - Lifecycle policies for cost optimization
  - Cross-region replication support
  - EventBridge integration for scan notifications
- **Repositories**: Separate repositories for each microservice component

### Database and Storage Services

#### Amazon RDS (Relational Database Service)
- **Engine**: PostgreSQL 15
- **Configuration**:
  - Multi-AZ deployment for high availability
  - Automated backups with 7-day retention
  - Encryption at rest with customer-managed KMS keys
  - SSL enforcement via parameter groups
- **Integration**: Credentials managed via AWS Secrets Manager with automatic rotation

#### Amazon ElastiCache
- **Engine**: Redis 7.0
- **Configuration**:
  - Cluster mode enabled for production environments
  - Encryption in transit and at rest
  - Authentication tokens stored in Secrets Manager
  - Multi-AZ with automatic failover
- **Use Cases**: Session storage, application caching, rate limiting

#### Amazon Elastic Block Store (EBS)
- **Purpose**: Persistent storage for Kubernetes workloads
- **Integration**: EBS CSI driver for dynamic volume provisioning
- **Encryption**: All volumes encrypted with KMS

### Networking and Security Services

#### Amazon Virtual Private Cloud (VPC)
- **Architecture**: Multi-tier network with public, private, and database subnets
- **Availability Zones**: Distributed across 3 AZs for high availability
- **Components**:
  - Internet Gateway for public subnet access
  - NAT Gateways for secure outbound access from private subnets
  - Route tables with proper routing configurations
  - VPC Flow Logs for network monitoring

#### Security Groups
- **EKS Security Groups**: Control plane and node group communication
- **ALB Security Groups**: HTTP/HTTPS traffic from internet
- **RDS Security Groups**: Database access only from EKS nodes
- **ElastiCache Security Groups**: Cache access only from application pods
- **Lambda Security Groups**: Function-specific network access

#### AWS Application Load Balancer (ALB)
- **Purpose**: Layer 7 load balancing with path-based routing
- **Features**:
  - SSL termination (certificates managed by Cloudflare)
  - Health checks and target group management
  - Integration with EKS via AWS Load Balancer Controller

### Identity and Access Management

#### AWS Identity and Access Management (IAM)
- **Service Account Roles**:
  - AWS Load Balancer Controller role
  - EBS CSI Driver role
  - External Secrets Operator role
  - Cluster Autoscaler role
  - Application-specific service account roles
- **Features**: IRSA (IAM Roles for Service Accounts) for fine-grained permissions
- **Security**: Least privilege access with resource-specific ARNs

#### AWS Secrets Manager
- **Purpose**: Centralized secret management with automatic rotation
- **Features**:
  - Database credential rotation via Lambda functions
  - Integration with External Secrets Operator
  - Encryption with KMS
  - Versioning and rollback capabilities

### Monitoring and Logging

#### Amazon CloudWatch
- **Logs**: Centralized logging for EKS, RDS, and Lambda functions
- **Metrics**: Infrastructure and application performance monitoring
- **Container Insights**: EKS cluster and workload visibility
- **Alarms**: Automated alerting for critical metrics

#### AWS CloudTrail
- **Purpose**: API call logging and audit trail
- **Configuration**: Organization-wide trail with S3 storage
- **Security**: Log file validation and encryption

### Management and Deployment

#### AWS Systems Manager
- **Parameter Store**: Configuration management
- **Session Manager**: Secure shell access to EC2 instances
- **Patch Manager**: Automated patching for managed nodes

#### AWS Auto Scaling
- **EKS Node Groups**: Automatic scaling based on pod resource requests
- **Integration**: Cluster Autoscaler for intelligent scaling decisions

## 🔧 Third-Party Tools and Technologies

### Infrastructure as Code

#### Terraform
- **Version**: >= 1.5
- **Purpose**: Infrastructure as Code for AWS resource provisioning
- **Providers Used**:
  - AWS Provider (~> 5.0)
  - Random Provider (~> 3.1)
  - TLS Provider (~> 4.0)
- **State Management**: S3 backend with DynamoDB locking
- **Modules**: Modular architecture for reusable components

#### Terraform Cloud / Terraform Enterprise (Optional)
- **Purpose**: Remote state management and collaboration
- **Features**: Policy as code, cost estimation, team collaboration

### Container Orchestration

#### Kubernetes
- **Version**: 1.27+ (EKS managed)
- **Purpose**: Container orchestration and workload management
- **Core Components**:
  - Pod scheduling and scaling
  - Service discovery and load balancing
  - ConfigMaps and Secrets management
  - Ingress controllers

#### Helm
- **Version**: 3.x
- **Purpose**: Kubernetes package manager
- **Charts Used**:
  - AWS Load Balancer Controller
  - External Secrets Operator
  - Cluster Autoscaler
  - Application-specific charts

### CI/CD and Development Tools

#### GitHub Actions
- **Purpose**: Continuous Integration and Deployment
- **Workflows**:
  - Terraform plan and validation
  - Security scanning (Checkov, TFSec)
  - Cost estimation (Infracost)
  - Automated deployment

#### Docker
- **Purpose**: Container image building and packaging
- **Integration**: Images stored in Amazon ECR
- **Multi-stage builds**: Optimized for security and size

### Security and Compliance

#### Checkov
- **Purpose**: Static analysis for Terraform security best practices
- **Integration**: GitHub Actions for automated scanning
- **Policies**: CIS benchmarks and security frameworks

#### TFSec
- **Purpose**: Terraform security scanner
- **Integration**: CI/CD pipeline validation
- **Coverage**: AWS-specific security checks

#### Falco (Optional)
- **Purpose**: Runtime security monitoring
- **Deployment**: DaemonSet on EKS nodes
- **Rules**: Container and system call monitoring

### Monitoring and Observability

#### Prometheus (Optional)
- **Purpose**: Metrics collection and alerting
- **Deployment**: Kubernetes operator-based installation
- **Integration**: ServiceMonitor CRDs for service discovery

#### Grafana (Optional)
- **Purpose**: Metrics visualization and dashboards
- **Data Sources**: Prometheus, CloudWatch
- **Authentication**: OAuth integration

#### ArgoCD (Optional)
- **Purpose**: GitOps continuous deployment
- **Features**: Application lifecycle management
- **Security**: RBAC and SSO integration

## 🌐 External Services and Vendors

### DNS and CDN

#### Cloudflare Enterprise
- **Services Used**:
  - DNS management for advancedblockchainsecurity.com
  - Web Application Firewall (WAF)
  - DDoS protection
  - SSL/TLS certificate management
  - Global Content Delivery Network (CDN)
  - Zero Trust access controls
- **Integration**: CNAME records pointing to AWS ALB
- **Benefits**: Replaces AWS WAF, CloudFront, Route53 health checks, and certificate management

### Development and Collaboration

#### Git
- **Platform**: GitHub
- **Repository Structure**: Infrastructure as Code with environment separation
- **Branching Strategy**: Feature branches with main branch protection

#### Visual Studio Code / IDE
- **Extensions**: Terraform, Kubernetes, Docker
- **Remote Development**: Dev containers for consistent environments

### Cost Management

#### Infracost
- **Purpose**: Terraform cost estimation
- **Integration**: GitHub Actions for PR cost analysis
- **Features**: Multi-environment cost comparison

## 🔄 Service Integration Patterns

### Authentication and Authorization
```
GitHub Actions → AWS (OIDC) → EKS (IRSA) → AWS Services
```

### Secret Management Flow
```
AWS Secrets Manager → External Secrets Operator → Kubernetes Secrets → Pods
```

### Traffic Flow
```
Internet → Cloudflare → AWS ALB → EKS Ingress → Kubernetes Services → Pods
```

### Monitoring Data Flow
```
Applications → CloudWatch → Grafana/Prometheus → Alerting
```

## 📊 Cost Breakdown by Service Category

### Development Environment (~$320-400/month)
- **EKS**: ~$73/month (control plane)
- **EC2**: ~$45/month (t3.medium nodes)
- **RDS**: ~$15/month (db.t3.micro)
- **ElastiCache**: ~$12/month (cache.t3.micro)
- **ALB**: ~$25/month
- **NAT Gateway**: ~$45/month
- **Data Transfer**: ~$10/month
- **Other Services**: ~$20/month

### Production Environment (~$1,400+/month)
- Significantly higher costs due to larger instances, Multi-AZ, and enhanced monitoring

## 🛡️ Security Considerations

### Network Security
- Private subnets for all compute workloads
- Security groups with least privilege access
- VPC Flow Logs for network monitoring

### Data Security
- Encryption at rest for all data stores
- Encryption in transit for all communications
- Secrets rotation and centralized management

### Access Security
- IRSA for fine-grained AWS permissions
- Kubernetes RBAC for workload access control
- Cloudflare Zero Trust for application access

### Compliance
- CloudTrail for audit logging
- Resource tagging for compliance tracking
- Automated security scanning in CI/CD

## 📚 Version Matrix

| Service/Tool | Version | Purpose |
|--------------|---------|---------|
| Terraform | >= 1.5 | Infrastructure as Code |
| Kubernetes | 1.27+ | Container orchestration |
| PostgreSQL | 15 | Primary database |
| Redis | 7.0 | Caching and sessions |
| AWS CLI | >= 2.0 | AWS management |
| kubectl | >= 1.27 | Kubernetes management |
| Helm | 3.x | Package management |
| Docker | Latest | Container runtime |

This architecture provides a robust, scalable, and secure foundation for the Solidity Security platform while leveraging best practices for cloud-native applications.