#!/bin/bash

set -euo pipefail

# Task 1.6 Validation Script
# Validates the Kubernetes infrastructure components implementation

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="$SCRIPT_DIR/k8s"

function log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

function warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

function error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

function success() {
    echo -e "${GREEN}✓ $1${NC}"
}

function fail() {
    echo -e "${RED}✗ $1${NC}"
}

function check_file_exists() {
    local file="$1"
    local description="$2"

    if [[ -f "$file" ]]; then
        success "$description exists: $file"
        return 0
    else
        fail "$description missing: $file"
        return 1
    fi
}

function check_directory_exists() {
    local dir="$1"
    local description="$2"

    if [[ -d "$dir" ]]; then
        success "$description exists: $dir"
        return 0
    else
        fail "$description missing: $dir"
        return 1
    fi
}

function validate_yaml_syntax() {
    local file="$1"

    if command -v yq &> /dev/null; then
        if yq eval '.' "$file" &> /dev/null; then
            return 0
        else
            error "Invalid YAML syntax in $file"
            return 1
        fi
    else
        warn "yq not available, skipping YAML syntax validation for $file"
        return 0
    fi
}

function validate_kustomization() {
    local kustomization_file="$1"
    local description="$2"

    if [[ ! -f "$kustomization_file" ]]; then
        fail "$description kustomization.yaml missing"
        return 1
    fi

    success "$description kustomization.yaml found"

    if ! validate_yaml_syntax "$kustomization_file"; then
        return 1
    fi

    # Check if kustomize build works
    local dir="$(dirname "$kustomization_file")"
    if command -v kustomize &> /dev/null; then
        if kustomize build "$dir" &> /dev/null; then
            success "$description kustomization builds successfully"
        else
            fail "$description kustomization build failed"
            return 1
        fi
    else
        warn "kustomize not available, skipping build validation for $description"
    fi

    return 0
}

function validate_base_components() {
    log "Validating base components..."

    local base_dir="$K8S_DIR/base"
    local validation_failed=0

    # AWS Load Balancer Controller
    local alb_dir="$base_dir/aws-load-balancer-controller"
    if check_directory_exists "$alb_dir" "AWS Load Balancer Controller base directory"; then
        check_file_exists "$alb_dir/kustomization.yaml" "ALB Controller kustomization" || validation_failed=1
        check_file_exists "$alb_dir/service-account.yaml" "ALB Controller ServiceAccount" || validation_failed=1
        check_file_exists "$alb_dir/rbac.yaml" "ALB Controller RBAC" || validation_failed=1
        check_file_exists "$alb_dir/deployment.yaml" "ALB Controller Deployment" || validation_failed=1
        validate_kustomization "$alb_dir/kustomization.yaml" "ALB Controller" || validation_failed=1
    else
        validation_failed=1
    fi

    # cert-manager
    local cert_manager_dir="$base_dir/cert-manager"
    if check_directory_exists "$cert_manager_dir" "cert-manager base directory"; then
        check_file_exists "$cert_manager_dir/kustomization.yaml" "cert-manager kustomization" || validation_failed=1
        check_file_exists "$cert_manager_dir/namespace.yaml" "cert-manager Namespace" || validation_failed=1
        check_file_exists "$cert_manager_dir/deployment.yaml" "cert-manager Deployment" || validation_failed=1
        check_file_exists "$cert_manager_dir/service.yaml" "cert-manager Service" || validation_failed=1
        check_file_exists "$cert_manager_dir/webhook.yaml" "cert-manager Webhook" || validation_failed=1
        check_file_exists "$cert_manager_dir/cainjector.yaml" "cert-manager CAInjector" || validation_failed=1
        check_file_exists "$cert_manager_dir/cluster-issuer.yaml" "cert-manager ClusterIssuer" || validation_failed=1
        check_file_exists "$cert_manager_dir/cloudflare-secret.yaml" "cert-manager Cloudflare Secret" || validation_failed=1
        validate_kustomization "$cert_manager_dir/kustomization.yaml" "cert-manager" || validation_failed=1
    else
        validation_failed=1
    fi

    # External Secrets
    local external_secrets_dir="$base_dir/external-secrets"
    if check_directory_exists "$external_secrets_dir" "External Secrets base directory"; then
        check_file_exists "$external_secrets_dir/kustomization.yaml" "External Secrets kustomization" || validation_failed=1
        check_file_exists "$external_secrets_dir/namespace.yaml" "External Secrets Namespace" || validation_failed=1
        check_file_exists "$external_secrets_dir/operator.yaml" "External Secrets Operator" || validation_failed=1
        check_file_exists "$external_secrets_dir/cluster-secret-store.yaml" "External Secrets ClusterSecretStore" || validation_failed=1
        check_file_exists "$external_secrets_dir/rbac.yaml" "External Secrets RBAC" || validation_failed=1
        validate_kustomization "$external_secrets_dir/kustomization.yaml" "External Secrets" || validation_failed=1
    else
        validation_failed=1
    fi

    # Monitoring
    local monitoring_dir="$base_dir/monitoring"
    if check_directory_exists "$monitoring_dir" "Monitoring base directory"; then
        check_file_exists "$monitoring_dir/kustomization.yaml" "Monitoring kustomization" || validation_failed=1
        check_file_exists "$monitoring_dir/service-monitors.yaml" "Monitoring ServiceMonitors" || validation_failed=1
        validate_kustomization "$monitoring_dir/kustomization.yaml" "Monitoring" || validation_failed=1
    else
        validation_failed=1
    fi

    return $validation_failed
}

function validate_environment_overlays() {
    log "Validating environment overlays..."

    local overlays_dir="$K8S_DIR/overlays"
    local validation_failed=0

    for env in "staging" "production"; do
        local env_dir="$overlays_dir/$env/infrastructure"

        if check_directory_exists "$env_dir" "$env environment overlay directory"; then
            check_file_exists "$env_dir/kustomization.yaml" "$env kustomization" || validation_failed=1
            check_file_exists "$env_dir/alb-controller-patch.yaml" "$env ALB Controller patch" || validation_failed=1
            check_file_exists "$env_dir/alb-controller-deployment-patch.yaml" "$env ALB Controller deployment patch" || validation_failed=1
            check_file_exists "$env_dir/cert-manager-patch.yaml" "$env cert-manager patch" || validation_failed=1
            check_file_exists "$env_dir/external-secrets-patch.yaml" "$env External Secrets patch" || validation_failed=1
            check_file_exists "$env_dir/external-secrets-store-patch.yaml" "$env External Secrets store patch" || validation_failed=1
            validate_kustomization "$env_dir/kustomization.yaml" "$env infrastructure" || validation_failed=1
        else
            validation_failed=1
        fi
    done

    return $validation_failed
}

function validate_supporting_files() {
    log "Validating supporting files..."

    local validation_failed=0

    check_file_exists "$K8S_DIR/deploy-infrastructure.sh" "Deployment script" || validation_failed=1
    check_file_exists "$K8S_DIR/README-TASK-1.6.md" "Task 1.6 README" || validation_failed=1

    # Check if deployment script is executable
    if [[ -f "$K8S_DIR/deploy-infrastructure.sh" ]]; then
        if [[ -x "$K8S_DIR/deploy-infrastructure.sh" ]]; then
            success "Deployment script is executable"
        else
            fail "Deployment script is not executable"
            validation_failed=1
        fi
    fi

    return $validation_failed
}

function validate_yaml_files() {
    log "Validating YAML syntax for all files..."

    local validation_failed=0

    if command -v yq &> /dev/null; then
        while IFS= read -r -d '' yaml_file; do
            if ! validate_yaml_syntax "$yaml_file"; then
                validation_failed=1
            fi
        done < <(find "$K8S_DIR" -name "*.yaml" -print0)

        if [[ $validation_failed -eq 0 ]]; then
            success "All YAML files have valid syntax"
        fi
    else
        warn "yq not available, skipping comprehensive YAML validation"
    fi

    return $validation_failed
}

function generate_summary() {
    log "Generating Task 1.6 implementation summary..."

    echo ""
    echo "=== Task 1.6 Implementation Summary ==="
    echo ""
    echo "Base Components:"
    echo "  ✓ AWS Load Balancer Controller"
    echo "  ✓ cert-manager"
    echo "  ✓ External Secrets Operator"
    echo "  ✓ Monitoring (ServiceMonitors)"
    echo ""
    echo "Environment Overlays:"
    echo "  ✓ Staging environment configuration"
    echo "  ✓ Production environment configuration"
    echo ""
    echo "Supporting Files:"
    echo "  ✓ Deployment automation script"
    echo "  ✓ Comprehensive documentation"
    echo "  ✓ Validation script (this script)"
    echo ""
    echo "Directory Structure:"

    if command -v tree &> /dev/null; then
        tree "$K8S_DIR" -I "__pycache__|*.pyc"
    else
        find "$K8S_DIR" -type f | sort
    fi

    echo ""
    echo "Next Steps:"
    echo "1. Update IAM role ARNs in overlay patches"
    echo "2. Update VPC IDs and cluster names"
    echo "3. Configure Cloudflare API tokens"
    echo "4. Configure HashiCorp Vault endpoints"
    echo "5. Deploy using: ./k8s/deploy-infrastructure.sh [staging|production]"
    echo ""
}

function main() {
    log "Starting Task 1.6 validation..."

    local overall_result=0

    # Validate base components
    if ! validate_base_components; then
        overall_result=1
    fi

    # Validate environment overlays
    if ! validate_environment_overlays; then
        overall_result=1
    fi

    # Validate supporting files
    if ! validate_supporting_files; then
        overall_result=1
    fi

    # Validate YAML syntax
    if ! validate_yaml_files; then
        overall_result=1
    fi

    echo ""
    if [[ $overall_result -eq 0 ]]; then
        log "✅ Task 1.6 validation completed successfully!"
        generate_summary
    else
        error "❌ Task 1.6 validation failed. Please review the errors above."
        exit 1
    fi
}

# Script execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi