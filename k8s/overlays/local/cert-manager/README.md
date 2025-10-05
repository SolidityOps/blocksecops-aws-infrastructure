# Cert-Manager Local Development

## Prerequisites

### Install CRDs
Before deploying cert-manager, you must install the Custom Resource Definitions (CRDs):

```bash
# Install cert-manager CRDs
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.1/cert-manager.crds.yaml

# Verify CRDs are installed
kubectl get crd | grep cert-manager
```

### Deploy Cert-Manager
After CRDs are installed, deploy the cert-manager overlay:

```bash
# Deploy cert-manager local overlay
kubectl apply -k /Users/pwner/Git/ABS/solidity-security-aws-infrastructure/k8s/overlays/local/cert-manager/

# Verify deployment
kubectl get pods -n cert-manager-local
```

### Verify Installation
```bash
# Check that cert-manager is running
kubectl get pods -n cert-manager-local

# Verify ClusterIssuers are created
kubectl get clusterissuer

# Test certificate creation
kubectl get certificate -A
```

## Cleanup

```bash
# Remove cert-manager resources
kubectl delete -k /Users/pwner/Git/ABS/solidity-security-aws-infrastructure/k8s/overlays/local/cert-manager/

# Remove CRDs
kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.1/cert-manager.crds.yaml
```