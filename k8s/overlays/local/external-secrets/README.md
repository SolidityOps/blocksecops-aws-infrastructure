# External Secrets Operator Local Development

## Prerequisites

### Install CRDs
Before deploying external-secrets, you must install the Custom Resource Definitions (CRDs):

```bash
# Install external-secrets CRDs
kubectl apply -f https://raw.githubusercontent.com/external-secrets/external-secrets/main/deploy/crds/bundle.yaml

# Verify CRDs are installed
kubectl get crd | grep external-secrets
```

### Deploy External Secrets Operator
After CRDs are installed, deploy the external-secrets overlay:

```bash
# Deploy external-secrets local overlay
kubectl apply -k /Users/pwner/Git/ABS/solidity-security-aws-infrastructure/k8s/overlays/local/external-secrets/

# Verify deployment
kubectl get pods -n external-secrets-local
```

### Verify Installation
```bash
# Check that external-secrets is running
kubectl get pods -n external-secrets-local

# Verify ClusterSecretStores are created
kubectl get clustersecretstore

# Check webhook is running
kubectl get validatingwebhookconfiguration | grep external-secrets
```

## Configuration

The overlay includes ClusterSecretStore configurations for:
- **AWS Secrets Manager** (`aws-secrets-manager`)
- **Vault Backend** (`vault-backend`)

## Cleanup

```bash
# Remove external-secrets resources
kubectl delete -k /Users/pwner/Git/ABS/solidity-security-aws-infrastructure/k8s/overlays/local/external-secrets/

# Remove CRDs
kubectl delete -f https://raw.githubusercontent.com/external-secrets/external-secrets/main/deploy/crds/bundle.yaml
```