#!/bin/bash

# Task 1.6 Validation Script
# Validates Kubernetes Infrastructure Components Implementation

set -euo pipefail

echo "🔍 Task 1.6: Kubernetes Infrastructure Components Validation"
echo "=========================================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track validation results
validation_results=()

validate_component() {
    local component_name=$1
    local base_path=$2

    echo -e "\n📋 Validating ${component_name}..."

    # Check if directory exists
    if [[ ! -d "${base_path}" ]]; then
        echo -e "${RED}❌ Directory ${base_path} does not exist${NC}"
        validation_results+=("FAILED: ${component_name} - Missing directory")
        return 1
    fi

    # Check if kustomization.yaml exists
    if [[ ! -f "${base_path}/kustomization.yaml" ]]; then
        echo -e "${RED}❌ kustomization.yaml not found in ${base_path}${NC}"
        validation_results+=("FAILED: ${component_name} - Missing kustomization.yaml")
        return 1
    fi

    # Validate kustomize build
    if kubectl kustomize "${base_path}" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ ${component_name} base configuration is valid${NC}"
        validation_results+=("PASSED: ${component_name} base configuration")
    else
        echo -e "${RED}❌ ${component_name} kustomize validation failed${NC}"
        validation_results+=("FAILED: ${component_name} - Kustomize validation error")
        return 1
    fi
}

validate_overlay() {
    local env_name=$1
    local overlay_path=$2

    echo -e "\n🔧 Validating ${env_name} overlay..."

    # Check if overlay directory exists
    if [[ ! -d "${overlay_path}" ]]; then
        echo -e "${RED}❌ Overlay directory ${overlay_path} does not exist${NC}"
        validation_results+=("FAILED: ${env_name} overlay - Missing directory")
        return 1
    fi

    # Check if kustomization.yaml exists
    if [[ ! -f "${overlay_path}/kustomization.yaml" ]]; then
        echo -e "${RED}❌ kustomization.yaml not found in ${overlay_path}${NC}"
        validation_results+=("FAILED: ${env_name} overlay - Missing kustomization.yaml")
        return 1
    fi

    # Validate overlay kustomize build
    if kubectl kustomize "${overlay_path}" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ ${env_name} overlay configuration is valid${NC}"
        validation_results+=("PASSED: ${env_name} overlay configuration")
    else
        echo -e "${RED}❌ ${env_name} overlay kustomize validation failed${NC}"
        validation_results+=("FAILED: ${env_name} overlay - Kustomize validation error")
        return 1
    fi
}

# Set base directory
BASE_DIR="k8s"

echo -e "\n🏗️  Validating Base Components..."
echo "================================="

# Validate AWS Load Balancer Controller
validate_component "AWS Load Balancer Controller" "${BASE_DIR}/base/aws-load-balancer-controller"

# Validate cert-manager
validate_component "cert-manager" "${BASE_DIR}/base/cert-manager"

# Validate external-secrets
validate_component "external-secrets" "${BASE_DIR}/base/external-secrets"

# Validate monitoring
validate_component "monitoring" "${BASE_DIR}/base/monitoring"

echo -e "\n🌍 Validating Environment Overlays..."
echo "====================================="

# Validate staging overlay
validate_overlay "Staging" "${BASE_DIR}/overlays/staging"

# Validate production overlay
validate_overlay "Production" "${BASE_DIR}/overlays/production"

echo -e "\n📁 Validating Directory Structure..."
echo "===================================="

# Expected directories and files
expected_structure=(
    "k8s/base/aws-load-balancer-controller/kustomization.yaml"
    "k8s/base/aws-load-balancer-controller/service-account.yaml"
    "k8s/base/aws-load-balancer-controller/rbac.yaml"
    "k8s/base/aws-load-balancer-controller/deployment.yaml"
    "k8s/base/cert-manager/kustomization.yaml"
    "k8s/base/cert-manager/deployment.yaml"
    "k8s/base/cert-manager/cluster-issuer.yaml"
    "k8s/base/cert-manager/cloudflare-secret.yaml"
    "k8s/base/external-secrets/kustomization.yaml"
    "k8s/base/external-secrets/operator.yaml"
    "k8s/base/external-secrets/cluster-secret-store.yaml"
    "k8s/base/external-secrets/rbac.yaml"
    "k8s/base/monitoring/kustomization.yaml"
    "k8s/base/monitoring/service-monitors.yaml"
    "k8s/overlays/staging/kustomization.yaml"
    "k8s/overlays/staging/alb-controller-patch.yaml"
    "k8s/overlays/staging/cert-manager-patch.yaml"
    "k8s/overlays/staging/external-secrets-patch.yaml"
    "k8s/overlays/production/kustomization.yaml"
    "k8s/overlays/production/alb-controller-patch.yaml"
    "k8s/overlays/production/cert-manager-patch.yaml"
    "k8s/overlays/production/external-secrets-patch.yaml"
)

missing_files=()
for file in "${expected_structure[@]}"; do
    if [[ ! -f "${file}" ]]; then
        missing_files+=("${file}")
    fi
done

if [[ ${#missing_files[@]} -eq 0 ]]; then
    echo -e "${GREEN}✅ All expected files are present${NC}"
    validation_results+=("PASSED: Directory structure validation")
else
    echo -e "${RED}❌ Missing files:${NC}"
    for file in "${missing_files[@]}"; do
        echo -e "${RED}  - ${file}${NC}"
    done
    validation_results+=("FAILED: Directory structure - Missing files")
fi

echo -e "\n🧪 Validating Component Integration..."
echo "====================================="

# Check if staging overlay includes all base components
staging_resources=$(kubectl kustomize "${BASE_DIR}/overlays/staging" 2>/dev/null | grep -c "kind: " || echo "0")
if [[ $staging_resources -gt 20 ]]; then
    echo -e "${GREEN}✅ Staging overlay generates sufficient resources (${staging_resources})${NC}"
    validation_results+=("PASSED: Staging overlay resource generation")
else
    echo -e "${YELLOW}⚠️  Staging overlay generates fewer resources than expected (${staging_resources})${NC}"
    validation_results+=("WARNING: Staging overlay - Low resource count")
fi

# Check if production overlay includes all base components
production_resources=$(kubectl kustomize "${BASE_DIR}/overlays/production" 2>/dev/null | grep -c "kind: " || echo "0")
if [[ $production_resources -gt 20 ]]; then
    echo -e "${GREEN}✅ Production overlay generates sufficient resources (${production_resources})${NC}"
    validation_results+=("PASSED: Production overlay resource generation")
else
    echo -e "${YELLOW}⚠️  Production overlay generates fewer resources than expected (${production_resources})${NC}"
    validation_results+=("WARNING: Production overlay - Low resource count")
fi

echo -e "\n📊 Validation Summary"
echo "===================="

# Count results
passed_count=0
failed_count=0
warning_count=0

for result in "${validation_results[@]}"; do
    if [[ $result == PASSED* ]]; then
        ((passed_count++))
        echo -e "${GREEN}✅ ${result#PASSED: }${NC}"
    elif [[ $result == FAILED* ]]; then
        ((failed_count++))
        echo -e "${RED}❌ ${result#FAILED: }${NC}"
    elif [[ $result == WARNING* ]]; then
        ((warning_count++))
        echo -e "${YELLOW}⚠️  ${result#WARNING: }${NC}"
    fi
done

echo -e "\n📈 Results:"
echo -e "  ${GREEN}Passed: ${passed_count}${NC}"
echo -e "  ${RED}Failed: ${failed_count}${NC}"
echo -e "  ${YELLOW}Warnings: ${warning_count}${NC}"

if [[ $failed_count -eq 0 ]]; then
    echo -e "\n${GREEN}🎉 Task 1.6 validation completed successfully!${NC}"
    echo -e "${GREEN}All Kubernetes infrastructure components are properly configured.${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Task 1.6 validation failed with ${failed_count} errors.${NC}"
    echo -e "${RED}Please review and fix the issues above.${NC}"
    exit 1
fi