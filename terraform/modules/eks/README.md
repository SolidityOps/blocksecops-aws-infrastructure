# EKS Module - Task 1.5

This module provides a secure, scalable Amazon Elastic Kubernetes Service (EKS) cluster for the Solidity Security Platform, designed to support the comprehensive Kubernetes workloads including databases, monitoring, security, and application services.

## Features

### EKS Cluster
- **✅ Secure Cluster**: Private API endpoint, encryption at rest, comprehensive logging
- **✅ Multi-AZ Deployment**: High availability across multiple availability zones
- **✅ Managed Node Groups**: Auto-scaling, managed updates, optimized AMIs
- **✅ OIDC Integration**: Service account roles using OIDC identity provider
- **✅ Add-ons Management**: CoreDNS, kube-proxy, VPC CNI, EBS CSI driver
- **✅ Security Groups**: Network isolation and least-privilege access

### Node Groups
- **✅ Flexible Configuration**: Multiple node groups with different instance types
- **✅ Auto Scaling**: Cluster Autoscaler integration with ASG tags
- **✅ Cost Optimization**: Support for Spot instances and mixed instance types
- **✅ Custom Labels & Taints**: Kubernetes scheduling control
- **✅ Monitoring**: CloudWatch agent integration for node metrics

### Security Features
- **✅ Encryption**: KMS encryption for cluster secrets and EBS volumes
- **✅ IAM Integration**: OIDC-based service account roles
- **✅ Network Security**: Private subnets, security groups, NACLs
- **✅ Audit Logging**: Comprehensive control plane logging
- **✅ RBAC**: Role-based access control with cluster admin permissions

### Service Integrations
- **✅ AWS Load Balancer Controller**: Application and Network Load Balancer support
- **✅ EBS CSI Driver**: Persistent volume support with encryption
- **✅ Cluster Autoscaler**: Automatic node scaling based on pod demands
- **✅ VPC CNI**: Advanced networking with security groups for pods

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        VPC (from networking module)             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐                    ┌─────────────────┐    │
│  │  Public Subnets │                    │ Private Subnets │    │
│  │                 │                    │                 │    │
│  │  ┌───────────┐  │                    │  ┌───────────┐  │    │
│  │  │    ALB    │  │                    │  │EKS Worker │  │    │
│  │  │   (LB)    │  │                    │  │   Nodes   │  │    │
│  │  └───────────┘  │                    │  │           │  │    │
│  └─────────────────┘                    │  │ ┌───────┐ │  │    │
│                                         │  │ │ Pods  │ │  │    │
│  ┌─────────────────┐                    │  │ └───────┘ │  │    │
│  │ EKS Control     │                    │  └───────────┘  │    │
│  │ Plane (Managed) │◄───────────────────┤                 │    │
│  │                 │                    │  ┌───────────┐  │    │
│  │ ┌─────────────┐ │                    │  │   EBS     │  │    │
│  │ │   API       │ │                    │  │ Volumes   │  │    │
│  │ │  Server     │ │                    │  │(Encrypted)│  │    │
│  │ └─────────────┘ │                    │  └───────────┘  │    │
│  └─────────────────┘                    └─────────────────┘    │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                    AWS Services Integration                     │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │   IAM OIDC   │  │  CloudWatch  │  │     KMS      │         │
│  │   Provider   │  │    Logs      │  │  Encryption  │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
└─────────────────────────────────────────────────────────────────┘
```

## Usage

### Basic Usage

```hcl
module "eks" {
  source = "./modules/eks"

  project     = "solidity-security"
  environment = "staging"

  # Network configuration from networking module
  vpc_id                 = module.networking.vpc_id
  cluster_subnet_ids     = concat(module.networking.public_subnet_ids, module.networking.private_subnet_ids)
  node_group_subnet_ids  = module.networking.private_subnet_ids
  cluster_security_group_ids = [module.networking.eks_cluster_security_group_id]
  node_security_group_ids    = [module.networking.eks_nodes_security_group_id]

  # Cluster configuration
  cluster_version = "1.28"

  # Node groups
  node_groups = {
    default = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      min_size       = 1
      max_size       = 4
    }
  }

  tags = {
    Environment = "staging"
  }
}
```

### Production Configuration

```hcl
module "eks" {
  source = "./modules/eks"

  project     = "solidity-security"
  environment = "production"

  # Network configuration
  vpc_id                 = module.networking.vpc_id
  cluster_subnet_ids     = concat(module.networking.public_subnet_ids, module.networking.private_subnet_ids)
  node_group_subnet_ids  = module.networking.private_subnet_ids
  cluster_security_group_ids = [module.networking.eks_cluster_security_group_id]
  node_security_group_ids    = [module.networking.eks_nodes_security_group_id]

  # Cluster configuration - production optimized
  cluster_version                      = "1.28"
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access       = true
  cluster_enabled_log_types           = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Node groups - multiple for HA and cost optimization
  node_groups = {
    default = {
      instance_types = ["m5.large"]
      desired_size   = 3
      min_size       = 3
      max_size       = 10
      capacity_type  = "ON_DEMAND"
    }
    spot = {
      instance_types = ["m5.large", "m5.xlarge"]
      desired_size   = 2
      min_size       = 0
      max_size       = 5
      capacity_type  = "SPOT"
      k8s_taints = [
        {
          key    = "spot-instance"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]
    }
  }

  # Security - full encryption and monitoring
  enable_encryption = true
  create_cluster_security_group = true

  # Add-ons - comprehensive
  enable_ebs_csi_addon = true
  enable_pod_identity_addon = true

  # Service account roles
  enable_aws_load_balancer_controller = true
  enable_cluster_autoscaler = true

  tags = {
    Environment = "production"
  }
}
```

## Configuration Options

### Environment-Specific Defaults

#### Staging Environment
- **Node Groups**: Single t3.medium node group (1-3 nodes)
- **Logging**: Basic API and audit logs
- **Cost**: ~$100-150/month
- **Features**: Basic add-ons, no Pod Identity

#### Production Environment
- **Node Groups**: Multiple node groups with ON_DEMAND + SPOT
- **Logging**: Comprehensive control plane logging
- **Cost**: ~$300-500/month
- **Features**: All add-ons, Pod Identity, enhanced security

## Supported Workloads

Based on the existing Kubernetes manifests in `k8s/overlays/`, this EKS cluster supports:

### Core Infrastructure
- **AWS Load Balancer Controller**: ALB/NLB integration
- **Cluster Autoscaler**: Automatic node scaling
- **EBS CSI Driver**: Persistent storage
- **Metrics Server**: Resource metrics for HPA/VPA

### Database & Storage
- **PostgreSQL**: StatefulSets with persistent volumes
- **Vault**: Secret management and encryption

### Security & Certificates
- **Cert Manager**: Automatic TLS certificate management
- **External Secrets**: Integration with AWS Secrets Manager

### Monitoring & Observability
- **CloudWatch Integration**: Logs and metrics
- **Custom Metrics**: Application and cluster monitoring

## Security

### Cluster Security
- **API Endpoint**: Private access with optional public access
- **Encryption**: KMS encryption for secrets and EBS volumes
- **Logging**: Comprehensive audit and API logging
- **Authentication**: OIDC integration with IAM

### Network Security
- **Private Nodes**: Worker nodes in private subnets
- **Security Groups**: Least-privilege network access
- **VPC Integration**: Isolated network environment

### IAM & RBAC
- **Service Accounts**: OIDC-based IAM roles
- **Least Privilege**: Minimal required permissions
- **Cluster Admin**: Configurable admin access

## Service Account Roles

The module creates IAM roles for common Kubernetes services:

### AWS Load Balancer Controller
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aws-load-balancer-controller
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT:role/PROJECT-ENV-aws-load-balancer-controller-role
```

### Cluster Autoscaler
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cluster-autoscaler
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT:role/PROJECT-ENV-cluster-autoscaler-role
```

### EBS CSI Driver
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ebs-csi-controller-sa
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT:role/PROJECT-ENV-ebs-csi-driver-role
```

## Integration with Existing Components

### Networking Module
- Uses VPC, subnets, and security groups from networking module
- Integrates with existing network architecture

### Storage Module
- Can mount databases running in the cluster
- Uses EBS CSI driver for persistent storage

### Kubernetes Manifests
- Compatible with existing `k8s/overlays/` configurations
- Service account roles automatically created for existing services

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
cd environments/staging/eks
terraform init -backend-config=backend.tfvars
terraform apply -var-file=terraform.tfvars

# Production
cd environments/production/eks
terraform init -backend-config=backend.tfvars
terraform apply -var-file=terraform.tfvars
```

### Configure kubectl

```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-west-2 --name PROJECT-ENV-eks

# Verify cluster access
kubectl get nodes
kubectl get pods --all-namespaces
```

## Monitoring and Maintenance

### Key Metrics to Monitor
- **Cluster Health**: Node status, pod failures, resource utilization
- **Scaling**: Cluster Autoscaler events, node group scaling
- **Performance**: API latency, pod startup times
- **Security**: Audit log analysis, failed authentication attempts

### Maintenance Tasks
- **Updates**: Regular EKS version updates
- **Node Refresh**: Periodic node group replacement
- **Add-on Updates**: Keep add-ons current
- **Security**: Regular security group and RBAC reviews

## Cost Optimization

### Staging Optimizations
1. **Small Instances**: t3.medium for cost-effective development
2. **Single Node Group**: Simplified management
3. **Reduced Logging**: Basic logs only
4. **Spot Instances**: Optional for non-critical workloads

### Production Optimizations
1. **Mixed Instances**: ON_DEMAND + SPOT for cost balance
2. **Cluster Autoscaler**: Scale down during low usage
3. **Reserved Instances**: 1-3 year terms for predictable workloads
4. **Resource Limits**: Prevent resource waste

## Troubleshooting

### Common Issues
1. **Node Registration**: Check IAM roles and security groups
2. **Pod Scheduling**: Verify node labels, taints, and resources
3. **Service Discovery**: Check CoreDNS configuration
4. **Load Balancer**: Verify AWS Load Balancer Controller

### Useful Commands

```bash
# Check cluster status
kubectl get nodes -o wide
kubectl describe node NODE_NAME

# Check add-ons
kubectl get pods -n kube-system

# Check logs
kubectl logs -n kube-system -l app=aws-load-balancer-controller
kubectl logs -n kube-system -l app=cluster-autoscaler

# Check service accounts
kubectl get sa -n kube-system
kubectl describe sa SERVICE_ACCOUNT_NAME -n kube-system
```

## Future Enhancements

1. **GitOps Integration**: ArgoCD or Flux for application deployment
2. **Service Mesh**: Istio or App Mesh for advanced networking
3. **Advanced Monitoring**: Prometheus, Grafana, Jaeger
4. **Multi-Cluster**: Cross-region cluster federation
5. **Backup Solutions**: Velero for cluster and volume backups