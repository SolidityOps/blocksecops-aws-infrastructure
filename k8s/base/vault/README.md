# HashiCorp Vault Community Edition

## Overview

This directory contains Kustomize manifests for deploying HashiCorp Vault Community Edition in EKS.

**Important**: This deploys the Vault **server** that stores secrets. For secret injection into applications, see the External Secrets Operator which runs in separate `external-secrets-*` namespaces.

## Namespace Convention

### Vault Server Namespaces
- **Staging**: `vault-staging` - Hosts Vault server pods and storage
- **Production**: `vault-production` - Hosts Vault server pods and storage

### Related Namespaces (Separate Components)
- **External Secrets Staging**: `external-secrets-staging` - Hosts External Secrets Operator for secret injection
- **External Secrets Production**: `external-secrets-production` - Hosts External Secrets Operator for secret injection

> **Why Separate?** Vault stores secrets, External Secrets Operator fetches them and creates Kubernetes secrets for applications.

## Components

- **StatefulSet**: 3-node Raft cluster for high availability
- **Services**: Internal headless service and external ClusterIP service
- **ConfigMap**: Vault configuration with Raft storage
- **Ingress**: ALB ingress with cert-manager SSL
- **Init Job**: Helper job with setup instructions

## Key Features

- ✅ **Community Edition** (no enterprise features)
- ✅ **Manual unseal** with Shamir's secret sharing
- ✅ **Raft integrated storage** (no external dependencies)
- ✅ **Kubernetes authentication** for External Secrets Operator integration
- ✅ **High availability** with 3-node cluster

## Operations Documentation

**Complete operations guide**: See `solidity-security-docs/deployment/vault-community-operations.md`

## Quick Setup

1. **Deploy**: `kubectl apply -k k8s/overlays/staging/infrastructure`
2. **Initialize**: `kubectl exec -it vault-0 -n vault-staging -- vault operator init`
3. **Unseal**: Use 3 of 5 unseal keys on all pods
4. **Configure**: Set up Kubernetes auth and External Secrets Operator integration

## Important Notes

- **Manual operations required**: Vault Community Edition requires manual initialization and unsealing
- **No auto-unseal**: Pods must be manually unsealed after every restart
- **Secure key storage**: Unseal keys and root tokens must be stored securely
- **Environment separation**: Staging and production use completely separate Vault clusters

Refer to the operations guide for detailed setup and maintenance procedures.