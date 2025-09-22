#!/bin/bash

# Setup Terraform Backend - Creates S3 bucket and DynamoDB table for Terraform state

set -e

PROJECT_NAME="solidity-security"
ENVIRONMENT="${1:-dev}"
AWS_REGION="${2:-us-east-1}"

if [ -z "$ENVIRONMENT" ]; then
    echo "Usage: $0 <environment> [aws-region]"
    echo "Example: $0 dev us-east-1"
    exit 1
fi

echo "Setting up Terraform backend for $PROJECT_NAME-$ENVIRONMENT in $AWS_REGION"

# S3 bucket name
BUCKET_NAME="$PROJECT_NAME-terraform-state-$ENVIRONMENT"
DYNAMODB_TABLE="$PROJECT_NAME-terraform-locks-$ENVIRONMENT"

echo "Creating S3 bucket: $BUCKET_NAME"

# Create S3 bucket
aws s3 mb "s3://$BUCKET_NAME" --region "$AWS_REGION" || echo "Bucket may already exist"

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

# Enable server-side encryption
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'

# Block public access
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo "Creating DynamoDB table: $DYNAMODB_TABLE"

# Create DynamoDB table for state locking
aws dynamodb create-table \
    --table-name "$DYNAMODB_TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$AWS_REGION" || echo "Table may already exist"

echo "Waiting for DynamoDB table to be active..."
aws dynamodb wait table-exists --table-name "$DYNAMODB_TABLE" --region "$AWS_REGION"

echo "Backend setup complete!"
echo ""
echo "Update your terraform backend configuration:"
echo "bucket         = \"$BUCKET_NAME\""
echo "dynamodb_table = \"$DYNAMODB_TABLE\""
echo "region         = \"$AWS_REGION\""
echo ""
echo "Next steps:"
echo "1. cd terraform/environments/$ENVIRONMENT"
echo "2. terraform init"
echo "3. terraform plan"
echo "4. terraform apply"