# Local Development Overlays

This directory contains Kubernetes overlays optimized for local development using minikube.

## Available Overlays

### Infrastructure Components
- **postgresql** - PostgreSQL database (`postgresql-local` namespace)
- **redis** - Redis cache (`redis-local` namespace)
- **harbor** - Container image registry (`harbor-local` namespace)

### Security & Networking
- **cert-manager** - Certificate management (`cert-manager-local` namespace)
- **external-secrets** - Secret management (`external-secrets-local` namespace)
- **nginx-ingress-controller** - Ingress controller (`ingress-nginx-local` namespace)
- **network-policies** - Network security policies (multiple namespaces)

## Quick Start

### 1. Prerequisites
- minikube running
- kubectl configured for minikube context

### 2. Install CRDs (Required for cert-manager and external-secrets)
```bash
# Install all required CRDs
./install-crds.sh

# Or install manually:
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.1/cert-manager.crds.yaml
kubectl apply -f https://raw.githubusercontent.com/external-secrets/external-secrets/main/deploy/crds/bundle.yaml
```

### 3. Deploy Overlays

#### Core Infrastructure (deploy in order)
```bash
# Database
kubectl apply -k postgresql/

# Cache
kubectl apply -k redis/

# Container Registry
kubectl apply -k harbor/
```

#### Security & Networking
```bash
# Certificate Management (requires CRDs)
kubectl apply -k cert-manager/

# Secret Management (requires CRDs)
kubectl apply -k external-secrets/

# Ingress Controller
kubectl apply -k nginx-ingress-controller/

# Network Policies
kubectl apply -k network-policies/
```

### 4. Verify Deployments
```bash
# Check all pods
kubectl get pods -A

# Check services
kubectl get svc -A

# Check ingress
kubectl get ingress -A

# Check certificates
kubectl get certificate -A

# Check ClusterIssuers
kubectl get clusterissuer
```

## Local Access

### Harbor Registry
- **Web UI (HTTPS)**: https://harbor.local (via Ingress)
- **Web UI (HTTP)**: http://$(minikube ip):30880 (NodePort)
- **Credentials**: admin / Harbor12345
- **Registry**: harbor-core.harbor-local.svc.cluster.local

### Database Services
- **PostgreSQL (HTTPS)**: https://postgres.local (via Ingress)
- **Redis (HTTPS)**: https://redis.local (via Ingress)

### NGINX Ingress
- **HTTP**: http://$(minikube ip):30080
- **HTTPS**: https://$(minikube ip):30443

### Local Domains Setup
Add these entries to your `/etc/hosts` file for HTTPS access:
```
$(minikube ip) harbor.local
$(minikube ip) postgres.local
$(minikube ip) redis.local
```

## Resource Configuration

All overlays are configured with reduced resources for local development:
- **CPU**: 50m requests, 100m limits
- **Memory**: 64-128Mi requests, 128-256Mi limits
- **Storage**: Reduced PVC sizes (1-5Gi vs production 10-50Gi)

## Cleanup

```bash
# Remove all overlays
for overlay in postgresql redis harbor cert-manager external-secrets nginx-ingress-controller network-policies; do
  kubectl delete -k $overlay/ || true
done

# Remove CRDs
kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.1/cert-manager.crds.yaml
kubectl delete -f https://raw.githubusercontent.com/external-secrets/external-secrets/main/deploy/crds/bundle.yaml
```

## Troubleshooting

### Common Issues

1. **CRD not found errors**: Install CRDs first using `./install-crds.sh`
2. **Resource conflicts**: Check for existing resources with `kubectl get all -A`
3. **Storage issues**: Ensure minikube has sufficient disk space
4. **Network policies blocking traffic**: Check namespace labels and policies

### Useful Commands

```bash
# View logs
kubectl logs -f deployment/<deployment-name> -n <namespace>

# Port forward to access services locally
kubectl port-forward svc/<service-name> -n <namespace> <local-port>:<service-port>

# Debug networking
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh
```