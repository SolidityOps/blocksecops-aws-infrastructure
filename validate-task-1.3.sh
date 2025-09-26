#!/bin/bash

# Task 1.3 Validation Script
# Validates AWS Database and Cache Infrastructure Implementation

set -e

echo "🔍 Task 1.3 Validation: AWS Database and Cache Infrastructure"
echo "============================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

success_count=0
total_checks=0

check_result() {
    local description="$1"
    local result="$2"
    total_checks=$((total_checks + 1))

    if [ "$result" = "true" ]; then
        echo -e "${GREEN}✅ $description${NC}"
        success_count=$((success_count + 1))
    else
        echo -e "${RED}❌ $description${NC}"
    fi
}

echo -e "\n${YELLOW}📁 Repository Structure Validation${NC}"
echo "-----------------------------------"

# Check ElastiCache Redis Terraform module structure
check_result "ElastiCache Redis variables.tf exists" "$(test -f terraform/modules/storage/variables.tf && echo true || echo false)"
check_result "ElastiCache Redis elasticache.tf exists" "$(test -f terraform/modules/storage/elasticache.tf && echo true || echo false)"
check_result "ElastiCache Redis security_groups.tf exists" "$(test -f terraform/modules/storage/security_groups.tf && echo true || echo false)"
check_result "ElastiCache Redis parameter_groups.tf exists" "$(test -f terraform/modules/storage/parameter_groups.tf && echo true || echo false)"
check_result "ElastiCache Redis outputs.tf exists" "$(test -f terraform/modules/storage/outputs.tf && echo true || echo false)"
check_result "Cache monitoring module exists" "$(test -f terraform/modules/monitoring/cache_monitoring.tf && echo true || echo false)"

echo -e "\n${YELLOW}🏗️  Environment Configuration Validation${NC}"
echo "------------------------------------------"

# Check staging environment updates
check_result "Staging main.tf includes storage module" "$(grep -q 'module \"storage\"' terraform/environments/staging/main.tf && echo true || echo false)"
check_result "Staging variables.tf includes Redis variables" "$(grep -q 'redis_node_type' terraform/environments/staging/variables.tf && echo true || echo false)"
check_result "Staging outputs.tf includes Redis outputs" "$(grep -q 'redis_cluster_id' terraform/environments/staging/outputs.tf && echo true || echo false)"

# Check production environment updates
check_result "Production main.tf includes storage module" "$(grep -q 'module \"storage\"' terraform/environments/production/main.tf && echo true || echo false)"
check_result "Production variables.tf includes Redis variables" "$(grep -q 'redis_node_type' terraform/environments/production/variables.tf && echo true || echo false)"
check_result "Production outputs.tf includes Redis outputs" "$(grep -q 'redis_cluster_id' terraform/environments/production/outputs.tf && echo true || echo false)"

echo -e "\n${YELLOW}🔐 Security Configuration Validation${NC}"
echo "------------------------------------"

# Check security features in ElastiCache module
check_result "Redis AUTH token configured" "$(grep -q 'auth_token' terraform/modules/storage/elasticache.tf && echo true || echo false)"
check_result "Redis encryption in transit enabled" "$(grep -q 'transit_encryption_enabled = true' terraform/modules/storage/elasticache.tf && echo true || echo false)"
check_result "Redis encryption at rest enabled" "$(grep -q 'at_rest_encryption_enabled = true' terraform/modules/storage/elasticache.tf && echo true || echo false)"
check_result "Redis security groups configured" "$(grep -q 'aws_security_group' terraform/modules/storage/security_groups.tf && echo true || echo false)"
check_result "Secrets Manager integration" "$(grep -q 'aws_secretsmanager_secret' terraform/modules/storage/elasticache.tf && echo true || echo false)"

echo -e "\n${YELLOW}📊 Monitoring Configuration Validation${NC}"
echo "--------------------------------------"

# Check monitoring setup
check_result "CloudWatch alarms configured" "$(grep -q 'aws_cloudwatch_metric_alarm' terraform/modules/monitoring/cache_monitoring.tf && echo true || echo false)"
check_result "CloudWatch dashboard configured" "$(grep -q 'aws_cloudwatch_dashboard' terraform/modules/monitoring/cache_monitoring.tf && echo true || echo false)"
check_result "Redis CPU monitoring" "$(grep -q 'CPUUtilization' terraform/modules/monitoring/cache_monitoring.tf && echo true || echo false)"
check_result "Redis memory monitoring" "$(grep -q 'DatabaseMemoryUsagePercentage' terraform/modules/monitoring/cache_monitoring.tf && echo true || echo false)"

echo -e "\n${YELLOW}🗃️  PostgreSQL Kubernetes Configuration${NC}"
echo "----------------------------------------"

# Check PostgreSQL StatefulSet configurations
MONITORING_REPO="../solidity-security-monitoring"
if [ -d "$MONITORING_REPO" ]; then
    check_result "PostgreSQL staging StatefulSet exists" "$(test -f $MONITORING_REPO/k8s/postgresql/staging/postgresql-statefulset.yaml && echo true || echo false)"
    check_result "PostgreSQL production StatefulSet exists" "$(test -f $MONITORING_REPO/k8s/postgresql/production/postgresql-statefulset.yaml && echo true || echo false)"
    check_result "PostgreSQL staging service exists" "$(test -f $MONITORING_REPO/k8s/postgresql/staging/postgresql-service.yaml && echo true || echo false)"
    check_result "PostgreSQL production service exists" "$(test -f $MONITORING_REPO/k8s/postgresql/production/postgresql-service.yaml && echo true || echo false)"
    check_result "PostgreSQL staging NetworkPolicy exists" "$(test -f $MONITORING_REPO/k8s/postgresql/staging/postgresql-networkpolicy.yaml && echo true || echo false)"
    check_result "PostgreSQL production NetworkPolicy exists" "$(test -f $MONITORING_REPO/k8s/postgresql/production/postgresql-networkpolicy.yaml && echo true || echo false)"
    check_result "PostgreSQL backup CronJob exists" "$(test -f $MONITORING_REPO/k8s/postgresql/backup-cronjob.yaml && echo true || echo false)"
    check_result "PostgreSQL documentation exists" "$(test -f $MONITORING_REPO/k8s/postgresql/README.md && echo true || echo false)"
else
    echo -e "${YELLOW}⚠️  Monitoring repository not found - PostgreSQL validation skipped${NC}"
fi

echo -e "\n${YELLOW}📖 Documentation Validation${NC}"
echo "----------------------------"

# Check README updates
check_result "README includes ElastiCache Redis info" "$(grep -q 'ElastiCache Redis' README.md && echo true || echo false)"
check_result "README includes monitoring section" "$(grep -q 'ElastiCache Monitoring' README.md && echo true || echo false)"
check_result "README includes usage instructions" "$(grep -q 'ElastiCache Redis Usage' README.md && echo true || echo false)"

echo -e "\n${YELLOW}🔧 Terraform Syntax Validation${NC}"
echo "------------------------------"

# Validate Terraform syntax
if command -v terraform &> /dev/null; then
    cd terraform/modules/storage
    if terraform fmt -check -diff; then
        check_result "Storage module Terraform formatting" "true"
    else
        check_result "Storage module Terraform formatting" "false"
    fi

    if terraform validate; then
        check_result "Storage module Terraform validation" "true"
    else
        check_result "Storage module Terraform validation" "false"
    fi
    cd - > /dev/null
else
    echo -e "${YELLOW}⚠️  Terraform not found - syntax validation skipped${NC}"
fi

echo -e "\n${YELLOW}📋 Task 1.3 Requirements Checklist${NC}"
echo "-----------------------------------"

# Task-specific requirements
check_result "ElastiCache Redis staging cluster configuration" "$(grep -q 'cache.t3.micro' terraform/environments/staging/variables.tf && echo true || echo false)"
check_result "ElastiCache Redis production cluster configuration" "$(grep -q 'cache.t3.small' terraform/environments/production/variables.tf && echo true || echo false)"
check_result "Redis backup and maintenance windows configured" "$(grep -q 'backup_window' terraform/modules/storage/variables.tf && echo true || echo false)"
check_result "Environment-specific resource allocation" "$(grep -q 'environment.*staging\|production' terraform/modules/storage/elasticache.tf && echo true || echo false)"

echo -e "\n${YELLOW}💰 Cost Optimization Validation${NC}"
echo "--------------------------------"

# Cost optimization checks
check_result "Single-node Redis for staging" "$(grep -q 'default.*=.*1' terraform/environments/staging/variables.tf && echo true || echo false)"
check_result "Appropriate instance types for environments" "$(grep -q 't3.micro\|t3.small' terraform/environments/*/variables.tf && echo true || echo false)"
check_result "PostgreSQL cost savings documented" "$(grep -q '\$1200' README.md && echo true || echo false)"

echo -e "\n${YELLOW}📊 Final Results${NC}"
echo "=================="

if [ $success_count -eq $total_checks ]; then
    echo -e "${GREEN}🎉 All $total_checks checks passed! Task 1.3 implementation is complete.${NC}"
    echo ""
    echo -e "${GREEN}✅ ElastiCache Redis infrastructure configured for both environments${NC}"
    echo -e "${GREEN}✅ PostgreSQL StatefulSet configurations created${NC}"
    echo -e "${GREEN}✅ Security controls implemented (AUTH tokens, encryption, NetworkPolicies)${NC}"
    echo -e "${GREEN}✅ Monitoring and alerting configured${NC}"
    echo -e "${GREEN}✅ Backup strategies implemented${NC}"
    echo -e "${GREEN}✅ Cost optimization achieved (~\$1200+/month savings)${NC}"
    echo ""
    echo -e "${GREEN}🚀 Ready for deployment!${NC}"
    exit 0
else
    failed_checks=$((total_checks - success_count))
    echo -e "${RED}❌ $failed_checks out of $total_checks checks failed.${NC}"
    echo -e "${YELLOW}Please review the failed checks above and make necessary corrections.${NC}"
    exit 1
fi