#!/bin/bash

# Deploy Environment - Deploy a specific environment with validation

set -e

PROJECT_NAME="solidity-security"
ENVIRONMENT="${1:-dev}"
AWS_REGION="${2:-us-east-1}"
ACTION="${3:-plan}"

usage() {
    echo "Usage: $0 <environment> [aws-region] [action]"
    echo ""
    echo "Arguments:"
    echo "  environment: dev, staging, or production"
    echo "  aws-region:  AWS region (default: us-east-1)"
    echo "  action:      plan, apply, or destroy (default: plan)"
    echo ""
    echo "Examples:"
    echo "  $0 dev us-east-1 plan"
    echo "  $0 staging us-east-1 apply"
    echo "  $0 dev us-east-1 destroy"
    exit 1
}

if [ -z "$ENVIRONMENT" ]; then
    usage
fi

if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|production)$ ]]; then
    echo "Error: Environment must be dev, staging, or production"
    usage
fi

if [[ ! "$ACTION" =~ ^(plan|apply|destroy)$ ]]; then
    echo "Error: Action must be plan, apply, or destroy"
    usage
fi

echo "🚀 Deploying $PROJECT_NAME $ENVIRONMENT environment"
echo "Region: $AWS_REGION"
echo "Action: $ACTION"
echo ""

# Check prerequisites
command -v terraform >/dev/null 2>&1 || { echo "Error: terraform is required but not installed. Aborting." >&2; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "Error: aws CLI is required but not installed. Aborting." >&2; exit 1; }

# Check AWS credentials
aws sts get-caller-identity >/dev/null 2>&1 || { echo "Error: AWS credentials not configured. Aborting." >&2; exit 1; }

# Navigate to environment directory
ENV_DIR="terraform/environments/$ENVIRONMENT"
if [ ! -d "$ENV_DIR" ]; then
    echo "Error: Environment directory $ENV_DIR does not exist"
    exit 1
fi

cd "$ENV_DIR"

echo "📁 Working directory: $(pwd)"

# Initialize Terraform if needed
if [ ! -d ".terraform" ]; then
    echo "🔧 Initializing Terraform..."
    terraform init
fi

# Validate configuration
echo "✅ Validating Terraform configuration..."
terraform validate

# Check formatting
echo "📝 Checking Terraform formatting..."
if ! terraform fmt -check -recursive; then
    echo "Warning: Terraform files are not formatted correctly"
    echo "Run 'terraform fmt -recursive' to fix formatting"
fi

# Generate plan
echo "📋 Generating Terraform plan..."
if [ "$ACTION" = "destroy" ]; then
    terraform plan -destroy -detailed-exitcode -out=tfplan
    PLAN_EXIT_CODE=$?
else
    terraform plan -detailed-exitcode -out=tfplan
    PLAN_EXIT_CODE=$?
fi

# Interpret plan results
case $PLAN_EXIT_CODE in
    0)
        echo "✅ No changes detected"
        if [ "$ACTION" != "plan" ]; then
            echo "Nothing to apply or destroy"
            exit 0
        fi
        ;;
    1)
        echo "❌ Terraform plan failed"
        exit 1
        ;;
    2)
        echo "📋 Changes detected"
        ;;
esac

# Show plan summary
echo ""
echo "📊 Plan Summary:"
terraform show -no-color tfplan | head -20

# Proceed with apply/destroy if requested
if [ "$ACTION" = "apply" ] || [ "$ACTION" = "destroy" ]; then
    echo ""
    echo "⚠️  About to $ACTION infrastructure for $ENVIRONMENT environment"
    echo "This will make real changes to your AWS account!"
    echo ""

    if [ "$ACTION" = "destroy" ]; then
        echo "🚨 WARNING: This will DESTROY all resources in the $ENVIRONMENT environment!"
        echo "🚨 This action cannot be undone!"
        echo ""
    fi

    read -p "Are you sure you want to continue? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo "Operation cancelled"
        exit 0
    fi

    echo "🚀 Applying Terraform plan..."
    terraform apply tfplan

    if [ $? -eq 0 ]; then
        echo "✅ $ACTION completed successfully!"

        if [ "$ACTION" = "apply" ]; then
            echo ""
            echo "📋 Infrastructure outputs:"
            terraform output

            echo ""
            echo "🎯 Next steps:"
            if [ "$ENVIRONMENT" = "dev" ]; then
                echo "1. Configure DNS records in Cloudflare"
                echo "2. Update kubeconfig: aws eks update-kubeconfig --region $AWS_REGION --name $PROJECT_NAME-$ENVIRONMENT"
                echo "3. Deploy Kubernetes services"
                echo "4. Test the deployment"
            else
                echo "1. Verify the deployment"
                echo "2. Run integration tests"
                echo "3. Update monitoring alerts"
            fi
        fi
    else
        echo "❌ $ACTION failed!"
        exit 1
    fi
fi

# Cleanup
rm -f tfplan

echo ""
echo "🎉 Deployment script completed!"