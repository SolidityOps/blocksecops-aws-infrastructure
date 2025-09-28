# Task 1.6: Kubernetes Infrastructure Components

This directory contains the Kustomize-based Kubernetes infrastructure components for Task 1.6 as specified in the Sprint 1 documentation.

## Overview

Task 1.6 implements the essential Kubernetes infrastructure components required for the Solidity Security Platform:

- **AWS Load Balancer Controller**: Manages Application Load Balancers for ingress traffic
- **cert-manager**: Automates SSL certificate provisioning and management
- **External Secrets Operator**: Synchronizes secrets from HashiCorp Vault and AWS Secrets Manager
- **Monitoring**: ServiceMonitor configurations for Prometheus integration

## Directory Structure

```
k8s/
├── base/                                    # Kustomize base configurations
│   ├── aws-load-balancer-controller/        # ALB Controller base manifests
│   ├── cert-manager/                        # cert-manager base manifests
│   ├── external-secrets/                    # External Secrets Operator base manifests
│   └── monitoring/                          # Monitoring base manifests
├── overlays/                                # Environment-specific overlays
│   ├── staging/infrastructure/              # Staging environment configuration
│   └── production/infrastructure/           # Production environment configuration
├── deploy-infrastructure.sh                 # Deployment automation script
└── README-TASK-1.6.md                      # This documentation
```

## Components

### AWS Load Balancer Controller

**Purpose**: Manages AWS Application Load Balancers for Kubernetes ingress resources.

**Key Features**:
- Automatic ALB provisioning and configuration
- Integration with VPC subnets and security groups
- Support for SSL termination and WAF integration
- IRSA (IAM Roles for Service Accounts) authentication

**Configuration**:
- Base manifests in `base/aws-load-balancer-controller/`
- Environment-specific patches for cluster names, VPC IDs, and IAM roles
- Production environment includes enhanced security features (WAF, Shield)

### cert-manager

**Purpose**: Automates SSL certificate provisioning using Let's Encrypt and DNS validation.

**Key Features**:
- Let's Encrypt integration with staging and production issuers
- Cloudflare DNS validation for domain ownership proof
- Automatic certificate renewal and management
- Integration with ingress controllers for SSL termination

**Configuration**:
- Base manifests in `base/cert-manager/`
- ClusterIssuers for both staging and production Let's Encrypt endpoints
- Cloudflare API token secret for DNS validation
- Environment-specific domain and email configuration

### External Secrets Operator

**Purpose**: Synchronizes secrets from external systems (HashiCorp Vault, AWS Secrets Manager).

**Key Features**:
- HashiCorp Vault integration with Kubernetes authentication
- AWS Secrets Manager integration with IRSA
- Automatic secret synchronization and rotation
- ClusterSecretStore configuration for multi-environment support

**Configuration**:
- Base manifests in `base/external-secrets/`
- ClusterSecretStores for Vault and AWS Secrets Manager
- Environment-specific Vault endpoints and AWS regions
- IRSA configuration for secure AWS access

### Monitoring

**Purpose**: Provides monitoring integration for all infrastructure components.

**Key Features**:
- ServiceMonitor resources for Prometheus integration
- Metrics collection from all infrastructure components
- Standardized monitoring labels and annotations

**Configuration**:
- Base manifests in `base/monitoring/`
- ServiceMonitors for ALB Controller, cert-manager, and External Secrets

## Deployment

### Prerequisites

1. **Kubernetes Cluster**: EKS cluster must be deployed and accessible
2. **kubectl**: Configured with appropriate cluster access
3. **kustomize**: Available in PATH for manifest building
4. **IAM Roles**: IRSA roles must be created for service accounts
5. **Secrets**: Cloudflare API tokens and Vault configuration

### Quick Deployment

```bash
# Deploy to staging environment
./deploy-infrastructure.sh staging

# Deploy to production environment
./deploy-infrastructure.sh production
```

### Manual Deployment

```bash
# Build and review manifests
kustomize build overlays/staging/infrastructure > staging-infrastructure.yaml

# Apply to cluster
kubectl apply -f staging-infrastructure.yaml
```

### Configuration Updates Required

Before deployment, update the following placeholders in overlay patches:

#### Staging Environment (`overlays/staging/infrastructure/`)

1. **ALB Controller Patch** (`alb-controller-patch.yaml`):
   ```yaml
   eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/staging-eks-alb-controller-role
   ```

2. **ALB Deployment Patch** (`alb-controller-deployment-patch.yaml`):
   ```yaml
   - --cluster-name=staging-solidity-security-cluster
   - --aws-vpc-id=vpc-staging-placeholder
   ```

3. **External Secrets Patch** (`external-secrets-patch.yaml`):
   ```yaml
   eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/staging-eks-external-secrets-role
   ```

4. **Vault Configuration** (`external-secrets-store-patch.yaml`):
   ```yaml
   server: "https://vault.staging.advancedblockchainsecurity.com"
   ```

#### Production Environment (`overlays/production/infrastructure/`)

Similar updates required with production-specific values:
- Production IAM role ARNs
- Production cluster name and VPC ID
- Production Vault endpoint
- Enhanced security settings (WAF, Shield enabled)

### Secret Management

#### Cloudflare API Token

Create the Cloudflare API token secret:

```bash
kubectl create secret generic cloudflare-api-token-secret \
  --from-literal=api-token=YOUR_CLOUDFLARE_API_TOKEN \
  -n cert-manager
```

#### Vault Authentication

Ensure HashiCorp Vault is configured with Kubernetes authentication:

```bash
# Enable Kubernetes auth method in Vault
vault auth enable kubernetes

# Configure Kubernetes auth
vault write auth/kubernetes/config \
  token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  kubernetes_host="https://kubernetes.default.svc" \
  kubernetes_ca_cert="$(cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt)"

# Create external-secrets role
vault write auth/kubernetes/role/external-secrets \
  bound_service_account_names=external-secrets \
  bound_service_account_namespaces=external-secrets \
  policies=external-secrets-policy \
  ttl=24h
```

## Verification

### Post-Deployment Checks

1. **Verify Deployments**:
   ```bash
   kubectl get deployments -A | grep -E "(aws-load-balancer|cert-manager|external-secrets)"
   ```

2. **Check ClusterIssuers**:
   ```bash
   kubectl get clusterissuer
   ```

3. **Verify ClusterSecretStores**:
   ```bash
   kubectl get clustersecretstore
   ```

4. **Test Certificate Issuance**:
   ```bash
   # Create test certificate
   kubectl apply -f - <<EOF
   apiVersion: cert-manager.io/v1
   kind: Certificate
   metadata:
     name: test-cert
     namespace: default
   spec:
     secretName: test-cert-tls
     issuerRef:
       name: letsencrypt-staging
       kind: ClusterIssuer
     dnsNames:
     - test.advancedblockchainsecurity.com
   EOF
   ```

5. **Monitor Components**:
   ```bash
   # Check component logs
   kubectl logs -n kube-system deployment/aws-load-balancer-controller
   kubectl logs -n cert-manager deployment/cert-manager
   kubectl logs -n external-secrets deployment/external-secrets
   ```

### Troubleshooting

#### Common Issues

1. **IRSA Authentication Failures**:
   - Verify IAM roles exist and have correct trust policies
   - Check service account annotations match IAM role ARNs
   - Ensure OIDC provider is configured for the EKS cluster

2. **cert-manager DNS Challenges**:
   - Verify Cloudflare API token has correct permissions
   - Check DNS propagation for domain validation
   - Review cert-manager logs for detailed error messages

3. **External Secrets Synchronization**:
   - Verify Vault authentication and policies
   - Check AWS IAM permissions for Secrets Manager access
   - Review ClusterSecretStore configuration

4. **Load Balancer Provisioning**:
   - Verify VPC and subnet configuration
   - Check security group rules for ALB access
   - Ensure ALB Controller has correct AWS permissions

## Integration with ArgoCD

These infrastructure components are designed to be managed by ArgoCD (Task 1.8). The Kustomize structure supports GitOps workflows:

```yaml
# ArgoCD Application example
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: infrastructure-staging
spec:
  source:
    repoURL: https://github.com/your-org/solidity-security-aws-infrastructure
    path: k8s/overlays/staging/infrastructure
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
```

## Security Considerations

1. **IRSA Configuration**: All service accounts use IAM Roles for Service Accounts for secure AWS access
2. **Secret Management**: Sensitive configuration stored in HashiCorp Vault or AWS Secrets Manager
3. **Network Policies**: Production environment includes enhanced network security
4. **Resource Limits**: All components have appropriate resource limits and security contexts
5. **RBAC**: Least-privilege access controls for all service accounts

## Next Steps

After successful deployment of Task 1.6 components:

1. **Configure DNS Records**: Create A records pointing to ALB endpoints (deployment pause point)
2. **Deploy ArgoCD**: Proceed with Task 1.8 for GitOps workflow management
3. **Service Deployment**: Deploy application services using the established infrastructure
4. **Monitoring Setup**: Configure Prometheus and Grafana to collect infrastructure metrics

## Support

For issues or questions regarding Task 1.6 implementation:

1. Review component logs using kubectl
2. Check AWS CloudTrail for IAM and service-related events
3. Verify network connectivity and DNS resolution
4. Consult the troubleshooting section above

This infrastructure foundation provides the essential components required for the Solidity Security Platform's Kubernetes environment and supports the progression to subsequent sprint tasks.