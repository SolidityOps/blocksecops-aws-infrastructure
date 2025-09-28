#!/bin/bash

set -euo pipefail

# Deploy Infrastructure Components Script
# This script deploys the Kubernetes infrastructure components for Task 1.6

ENVIRONMENT="${1:-staging}"
VALID_ENVIRONMENTS=("staging" "production")

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

function log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

function warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

function error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

function validate_environment() {
    local env="$1"
    if [[ ! " ${VALID_ENVIRONMENTS[@]} " =~ " ${env} " ]]; then
        error "Invalid environment: $env. Valid environments: ${VALID_ENVIRONMENTS[*]}"
    fi
}

function check_prerequisites() {
    log "Checking prerequisites..."

    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        error "kubectl is not installed or not in PATH"
    fi

    # Check if kustomize is available
    if ! command -v kustomize &> /dev/null; then
        error "kustomize is not installed or not in PATH"
    fi

    # Check if we can connect to the cluster
    if ! kubectl cluster-info &> /dev/null; then
        error "Cannot connect to Kubernetes cluster. Please check your kubeconfig"
    fi

    log "Prerequisites check passed"
}

function deploy_infrastructure() {
    local env="$1"
    local overlay_path="overlays/${env}/infrastructure"

    log "Deploying infrastructure components for ${env} environment..."

    # Validate overlay path exists
    if [[ ! -d "$overlay_path" ]]; then
        error "Overlay path does not exist: $overlay_path"
    fi

    # Build and apply the kustomization
    log "Building kustomization for $env..."
    kustomize build "$overlay_path" > "/tmp/infrastructure-${env}.yaml"

    log "Applying infrastructure manifests..."
    kubectl apply -f "/tmp/infrastructure-${env}.yaml"

    # Wait for deployments to be ready
    log "Waiting for deployments to be ready..."

    # Wait for AWS Load Balancer Controller
    log "Waiting for AWS Load Balancer Controller..."
    kubectl wait --for=condition=available \
        --timeout=300s \
        deployment/aws-load-balancer-controller \
        -n kube-system

    # Wait for cert-manager
    log "Waiting for cert-manager..."
    kubectl wait --for=condition=available \
        --timeout=300s \
        deployment/cert-manager \
        -n cert-manager

    # Wait for external-secrets
    log "Waiting for external-secrets..."
    kubectl wait --for=condition=available \
        --timeout=300s \
        deployment/external-secrets \
        -n external-secrets

    log "Infrastructure deployment completed successfully for $env environment"
}

function verify_deployment() {
    local env="$1"

    log "Verifying deployment..."

    # Check AWS Load Balancer Controller
    if kubectl get deployment aws-load-balancer-controller -n kube-system &> /dev/null; then
        log "✓ AWS Load Balancer Controller is deployed"
    else
        warn "✗ AWS Load Balancer Controller deployment not found"
    fi

    # Check cert-manager
    if kubectl get deployment cert-manager -n cert-manager &> /dev/null; then
        log "✓ cert-manager is deployed"
    else
        warn "✗ cert-manager deployment not found"
    fi

    # Check external-secrets
    if kubectl get deployment external-secrets -n external-secrets &> /dev/null; then
        log "✓ External Secrets Operator is deployed"
    else
        warn "✗ External Secrets Operator deployment not found"
    fi

    # Check ClusterIssuers
    if kubectl get clusterissuer letsencrypt-staging &> /dev/null; then
        log "✓ Let's Encrypt staging ClusterIssuer is created"
    else
        warn "✗ Let's Encrypt staging ClusterIssuer not found"
    fi

    if kubectl get clusterissuer letsencrypt-production &> /dev/null; then
        log "✓ Let's Encrypt production ClusterIssuer is created"
    else
        warn "✗ Let's Encrypt production ClusterIssuer not found"
    fi

    # Check ClusterSecretStores
    if kubectl get clustersecretstore vault-backend &> /dev/null; then
        log "✓ Vault ClusterSecretStore is created"
    else
        warn "✗ Vault ClusterSecretStore not found"
    fi

    if kubectl get clustersecretstore aws-secrets-manager &> /dev/null; then
        log "✓ AWS Secrets Manager ClusterSecretStore is created"
    else
        warn "✗ AWS Secrets Manager ClusterSecretStore not found"
    fi
}

function main() {
    log "Starting infrastructure deployment for Task 1.6..."

    validate_environment "$ENVIRONMENT"
    check_prerequisites
    deploy_infrastructure "$ENVIRONMENT"
    verify_deployment "$ENVIRONMENT"

    log "Task 1.6 infrastructure deployment completed successfully!"
    log "Next steps:"
    log "1. Update IAM role ARNs in the overlay patches"
    log "2. Update VPC IDs and cluster names in the patches"
    log "3. Configure Cloudflare API tokens for cert-manager"
    log "4. Configure HashiCorp Vault endpoints"
    log "5. Test the infrastructure components"
}

# Script execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi