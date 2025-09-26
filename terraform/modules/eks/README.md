# EKS Terraform Module

This Terraform module creates and manages Amazon EKS (Elastic Kubernetes Service) clusters with managed node groups, comprehensive monitoring, and autoscaling capabilities.

## Features

- **EKS Cluster**: Production-ready Kubernetes cluster with configurable versions
- **Managed Node Groups**: Auto-scaling node groups with multiple instance type support
- **Security**: Comprehensive security groups and IAM roles with least privilege
- **Monitoring**: CloudWatch logging, Container Insights, and custom dashboards
- **Autoscaling**: Cluster Autoscaler with IRSA (IAM Roles for Service Accounts)
- **High Availability**: Multi-AZ deployment support for production workloads

## Usage

### Basic Usage

```hcl
module "eks_cluster" {
  source = "./modules/eks"

  cluster_name = "my-cluster"
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnet_ids

  node_group_subnet_ids = module.vpc.private_subnet_ids

  tags = {
    Environment = "staging"
    Project     = "solidity-security"
  }
}
```

### Production Configuration

```hcl
module "eks_production" {
  source = "./modules/eks"

  cluster_name       = "solidity-security-eks-production"
  kubernetes_version = "1.28"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  # Node group configuration
  node_group_subnet_ids    = module.vpc.private_subnet_ids
  node_group_instance_types = ["t3.large", "t3.xlarge", "m5.large"]
  node_group_desired_size   = 3
  node_group_max_size       = 10
  node_group_min_size       = 2

  # Enable production features
  enable_container_insights = true
  sns_topic_arn            = aws_sns_topic.alerts.arn

  # Security
  endpoint_private_access = true
  endpoint_public_access  = true
  public_access_cidrs     = ["10.0.0.0/8"]

  tags = {
    Environment = "production"
    Project     = "solidity-security"
    Compliance  = "required"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |
| tls | >= 3.0 |

## Inputs

### Required Inputs

| Name | Description | Type |
|------|-------------|------|
| cluster_name | Name of the EKS cluster | `string` |
| vpc_id | VPC ID where the cluster will be deployed | `string` |
| subnet_ids | List of subnet IDs for the EKS cluster | `list(string)` |
| node_group_subnet_ids | List of subnet IDs for the node group | `list(string)` |

### Optional Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| kubernetes_version | Kubernetes version for the EKS cluster | `string` | `"1.28"` |
| node_group_instance_types | List of instance types for the node group | `list(string)` | `["t3.medium"]` |
| node_group_desired_size | Desired number of worker nodes | `number` | `2` |
| node_group_max_size | Maximum number of worker nodes | `number` | `4` |
| node_group_min_size | Minimum number of worker nodes | `number` | `1` |
| enable_container_insights | Enable CloudWatch Container Insights | `bool` | `true` |
| sns_topic_arn | SNS topic ARN for CloudWatch alarms | `string` | `""` |

See [variables.tf](./variables.tf) for the complete list of inputs.

## Outputs

### Cluster Outputs

| Name | Description |
|------|-------------|
| cluster_id | The ID of the EKS cluster |
| cluster_arn | The Amazon Resource Name (ARN) of the cluster |
| cluster_endpoint | Endpoint for EKS control plane |
| cluster_security_group_id | Security group ID attached to the EKS cluster |
| kubeconfig | kubectl config file contents for this EKS cluster |

### Monitoring Outputs

| Name | Description |
|------|-------------|
| cloudwatch_dashboard_name | Name of the CloudWatch dashboard |
| cloudwatch_dashboard_url | URL of the CloudWatch dashboard |
| container_insights_log_groups | List of Container Insights log group names |

See [outputs.tf](./outputs.tf) for the complete list of outputs.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                           VPC                                   │
│  ┌─────────────────┐    ┌─────────────────┐    ┌──────────────┐  │
│  │   Private       │    │   Private       │    │   Public     │  │
│  │   Subnet AZ-A   │    │   Subnet AZ-B   │    │   Subnet     │  │
│  │                 │    │                 │    │              │  │
│  │  ┌───────────┐  │    │  ┌───────────┐  │    │              │  │
│  │  │    EKS    │  │    │  │    EKS    │  │    │              │  │
│  │  │   Nodes   │  │    │  │   Nodes   │  │    │              │  │
│  │  └───────────┘  │    │  └───────────┘  │    │              │  │
│  └─────────────────┘    └─────────────────┘    └──────────────┘  │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                EKS Control Plane                           │ │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐  │ │
│  │  │ API Server  │ │ Controller  │ │     Scheduler       │  │ │
│  │  │             │ │   Manager   │ │                     │  │ │
│  │  └─────────────┘ └─────────────┘ └─────────────────────┘  │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                │
                    ┌───────────▼──────────┐
                    │    CloudWatch        │
                    │   - Logs             │
                    │   - Metrics          │
                    │   - Dashboards       │
                    │   - Alarms           │
                    └──────────────────────┘
```

## Security Features

- **Network Security**: Private subnets with security groups
- **IAM Integration**: Least privilege IAM roles and policies
- **Encryption**: EKS secrets encryption with KMS
- **Audit Logging**: Comprehensive audit logs to CloudWatch
- **RBAC**: Kubernetes Role-Based Access Control
- **IRSA**: IAM Roles for Service Accounts for pod-level permissions

## Monitoring and Logging

- **CloudWatch Logs**: API server, audit, authenticator, controller manager, scheduler
- **Container Insights**: Pod and node-level metrics
- **Custom Dashboards**: EKS cluster health and performance metrics
- **Alerting**: CloudWatch alarms for critical events
- **Prometheus Integration**: ServiceMonitor and PrometheusRule configurations

## Autoscaling

- **Cluster Autoscaler**: Automatic node provisioning based on pod resource requests
- **Node Group Scaling**: Auto Scaling Groups with configurable min/max/desired capacity
- **Priority Expander**: Instance type prioritization for cost optimization
- **Multi-AZ Support**: Node distribution across availability zones

## Deployment with Kustomize

This module works with the Kustomize configurations in `../../../k8s/`:

```bash
# Deploy to staging
kubectl kustomize k8s/overlays/staging | kubectl apply -f -

# Deploy to production
kubectl kustomize k8s/overlays/production | kubectl apply -f -
```

## Validation

Use the provided validation script to verify the implementation:

```bash
./validate-task-1.5.sh
```

## Troubleshooting

### Common Issues

1. **Node groups not joining cluster**: Check security group rules and IAM policies
2. **Cluster autoscaler not working**: Verify IRSA configuration and IAM permissions
3. **Pods stuck in pending**: Check node resources and cluster autoscaler logs

### Debugging Commands

```bash
# Check cluster status
kubectl get nodes
kubectl get pods -A

# Check cluster autoscaler logs
kubectl logs -n cluster-autoscaler deployment/cluster-autoscaler

# Verify IAM roles
aws sts get-caller-identity
aws eks describe-cluster --name <cluster-name>
```

## Contributing

1. Update variables and outputs as needed
2. Ensure all resources have proper tags
3. Test with validation script
4. Update this README with any new features

## License

This module is part of the Solidity Security Platform and follows the project's licensing terms.