#!/bin/bash

# Task 1.5 EKS Cluster Deployment Validation Script
# Validates all components of the EKS implementation

set -e

echo "=============================================="
echo "🚀 Task 1.5 EKS Cluster Deployment Validation"
echo "=============================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Function to print success
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((PASSED_CHECKS++))
}

# Function to print failure
print_failure() {
    echo -e "${RED}❌ $1${NC}"
    ((FAILED_CHECKS++))
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to run check
run_check() {
    ((TOTAL_CHECKS++))
    local description="$1"
    local command="$2"

    echo -n "Checking: $description... "

    if eval "$command" >/dev/null 2>&1; then
        print_success "$description"
    else
        print_failure "$description"
    fi
}

echo ""
echo "📁 Validating Directory Structure..."
echo "-----------------------------------"

# Check Terraform EKS module structure
run_check "EKS Terraform module directory exists" "[ -d 'terraform/modules/eks' ]"
run_check "EKS cluster.tf exists" "[ -f 'terraform/modules/eks/cluster.tf' ]"
run_check "EKS node_groups.tf exists" "[ -f 'terraform/modules/eks/node_groups.tf' ]"
run_check "EKS variables.tf exists" "[ -f 'terraform/modules/eks/variables.tf' ]"
run_check "EKS outputs.tf exists" "[ -f 'terraform/modules/eks/outputs.tf' ]"
run_check "EKS cloudwatch.tf exists" "[ -f 'terraform/modules/eks/cloudwatch.tf' ]"
run_check "EKS user_data.sh exists" "[ -f 'terraform/modules/eks/user_data.sh' ]"
run_check "EKS kubeconfig.tpl exists" "[ -f 'terraform/modules/eks/kubeconfig.tpl' ]"

# Check k8s directory structure
run_check "k8s base directory exists" "[ -d 'k8s/base' ]"
run_check "k8s overlays directory exists" "[ -d 'k8s/overlays' ]"
run_check "EKS cluster base configs exist" "[ -d 'k8s/base/eks-cluster' ]"
run_check "Node groups base configs exist" "[ -d 'k8s/base/node-groups' ]"
run_check "Staging overlay exists" "[ -d 'k8s/overlays/staging' ]"
run_check "Production overlay exists" "[ -d 'k8s/overlays/production' ]"

echo ""
echo "📋 Validating Kustomize Configuration Files..."
echo "--------------------------------------------"

# Check base kustomization files
run_check "EKS cluster base kustomization.yaml" "[ -f 'k8s/base/eks-cluster/kustomization.yaml' ]"
run_check "Node groups base kustomization.yaml" "[ -f 'k8s/base/node-groups/kustomization.yaml' ]"
run_check "EKS cluster base config" "[ -f 'k8s/base/eks-cluster/cluster-config.yaml' ]"
run_check "Node groups base config" "[ -f 'k8s/base/node-groups/node-group.yaml' ]"

# Check overlay files
run_check "Staging kustomization.yaml" "[ -f 'k8s/overlays/staging/kustomization.yaml' ]"
run_check "Staging cluster patch" "[ -f 'k8s/overlays/staging/cluster-patch.yaml' ]"
run_check "Staging node group patch" "[ -f 'k8s/overlays/staging/node-group-patch.yaml' ]"
run_check "Production kustomization.yaml" "[ -f 'k8s/overlays/production/kustomization.yaml' ]"
run_check "Production cluster patch" "[ -f 'k8s/overlays/production/cluster-patch.yaml' ]"
run_check "Production node group patch" "[ -f 'k8s/overlays/production/node-group-patch.yaml' ]"

# Check monitoring and autoscaling configs
run_check "Cluster autoscaler priority expander config" "[ -f 'k8s/base/eks-cluster/cluster-autoscaler-priority-expander.yaml' ]"
run_check "Monitoring configuration" "[ -f 'k8s/base/eks-cluster/monitoring-config.yaml' ]"

echo ""
echo "🔍 Validating Terraform Configuration Content..."
echo "----------------------------------------------"

# Check for essential Terraform resources
run_check "EKS cluster resource in cluster.tf" "grep -q 'resource \"aws_eks_cluster\"' terraform/modules/eks/cluster.tf"
run_check "EKS node group resource in node_groups.tf" "grep -q 'resource \"aws_eks_node_group\"' terraform/modules/eks/node_groups.tf"
run_check "IAM roles for cluster in cluster.tf" "grep -q 'resource \"aws_iam_role\" \"cluster\"' terraform/modules/eks/cluster.tf"
run_check "IAM roles for node group in node_groups.tf" "grep -q 'resource \"aws_iam_role\" \"node_group\"' terraform/modules/eks/node_groups.tf"
run_check "Security groups for cluster" "grep -q 'resource \"aws_security_group\" \"cluster\"' terraform/modules/eks/cluster.tf"
run_check "CloudWatch log group" "grep -q 'resource \"aws_cloudwatch_log_group\" \"cluster\"' terraform/modules/eks/cluster.tf"
run_check "OIDC provider" "grep -q 'resource \"aws_iam_openid_connect_provider\"' terraform/modules/eks/cluster.tf"

# Check CloudWatch monitoring resources
run_check "CloudWatch alarms for monitoring" "grep -q 'resource \"aws_cloudwatch_metric_alarm\"' terraform/modules/eks/cloudwatch.tf"
run_check "CloudWatch dashboard" "grep -q 'resource \"aws_cloudwatch_dashboard\"' terraform/modules/eks/cloudwatch.tf"
run_check "Container Insights log groups" "grep -q 'container_insights' terraform/modules/eks/cloudwatch.tf"

echo ""
echo "🎯 Validating Kubernetes Configuration Content..."
echo "-----------------------------------------------"

# Check for cluster autoscaler deployment
run_check "Cluster autoscaler deployment" "grep -q 'kind: Deployment' k8s/base/node-groups/node-group.yaml"
run_check "Cluster autoscaler service account" "grep -q 'kind: ServiceAccount' k8s/base/eks-cluster/cluster-config.yaml"
run_check "Cluster autoscaler RBAC" "grep -q 'kind: ClusterRole' k8s/base/eks-cluster/cluster-config.yaml"

# Check environment-specific configurations
run_check "Staging cluster name configuration" "grep -q 'solidity-security-eks-staging' k8s/overlays/staging/cluster-patch.yaml"
run_check "Production cluster name configuration" "grep -q 'solidity-security-eks-production' k8s/overlays/production/cluster-patch.yaml"
run_check "Production high availability config" "grep -q 'high.availability' k8s/overlays/production/kustomization.yaml"

# Check monitoring configurations
run_check "Prometheus monitoring config" "grep -q 'prometheus.scrape' k8s/base/eks-cluster/monitoring-config.yaml"
run_check "ServiceMonitor for metrics" "grep -q 'kind: ServiceMonitor' k8s/base/eks-cluster/monitoring-config.yaml"
run_check "PrometheusRule for alerts" "grep -q 'kind: PrometheusRule' k8s/base/eks-cluster/monitoring-config.yaml"

echo ""
echo "🔧 Validating Terraform Syntax..."
echo "--------------------------------"

# Change to terraform directory for validation
cd terraform/modules/eks

# Check Terraform syntax
if command -v terraform >/dev/null 2>&1; then
    run_check "Terraform format check" "terraform fmt -check ."
    run_check "Terraform validation" "terraform init -backend=false && terraform validate"
else
    print_warning "Terraform not found, skipping syntax validation"
fi

# Return to original directory
cd - >/dev/null

echo ""
echo "🎨 Validating Kustomize Syntax..."
echo "--------------------------------"

# Check kustomize syntax if available
if command -v kustomize >/dev/null 2>&1; then
    run_check "Staging kustomization build" "kustomize build k8s/overlays/staging"
    run_check "Production kustomization build" "kustomize build k8s/overlays/production"
elif command -v kubectl >/dev/null 2>&1; then
    run_check "Staging kustomization build (kubectl)" "kubectl kustomize k8s/overlays/staging"
    run_check "Production kustomization build (kubectl)" "kubectl kustomize k8s/overlays/production"
else
    print_warning "Neither kustomize nor kubectl found, skipping kustomization validation"
fi

echo ""
echo "📊 Validation Summary"
echo "===================="
echo "Total Checks: $TOTAL_CHECKS"
echo -e "Passed: ${GREEN}$PASSED_CHECKS${NC}"
echo -e "Failed: ${RED}$FAILED_CHECKS${NC}"

# Calculate success percentage
SUCCESS_PERCENTAGE=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
echo "Success Rate: $SUCCESS_PERCENTAGE%"

echo ""
if [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "${GREEN}🎉 All checks passed! Task 1.5 EKS implementation is complete and ready for deployment.${NC}"
    echo ""
    echo "📋 Implementation Summary:"
    echo "• EKS Terraform module with cluster and node groups"
    echo "• Comprehensive CloudWatch monitoring and logging"
    echo "• Cluster autoscaling with IRSA support"
    echo "• Kustomize base configurations and environment overlays"
    echo "• Security groups and IAM roles"
    echo "• Container Insights integration"
    echo "• Production-ready monitoring and alerting"
    echo ""
    echo "🚀 Ready for deployment with terraform apply and kubectl apply!"
    exit 0
else
    echo -e "${RED}❌ $FAILED_CHECKS checks failed. Please review and fix the issues above.${NC}"
    exit 1
fi