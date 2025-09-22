# Secrets Manager Module - Creates and manages AWS Secrets Manager secrets with rotation

locals {
  # Define secret configurations
  secret_configs = {
    for secret in var.secrets : secret.name => secret
  }
}

# Secrets Manager Secrets
resource "aws_secretsmanager_secret" "secrets" {
  for_each = local.secret_configs

  name        = "${var.project_name}-${var.environment}/${each.value.path}"
  description = each.value.description
  kms_key_id  = var.kms_key_arn

  # Automatic rotation configuration
  dynamic "rotation_rules" {
    for_each = each.value.rotation_enabled ? [1] : []
    content {
      automatically_after_days = each.value.rotation_days
    }
  }

  # Replica configuration for cross-region
  dynamic "replica" {
    for_each = each.value.replica_regions
    content {
      region     = replica.value.region
      kms_key_id = replica.value.kms_key_arn
    }
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-${each.key}"
      Environment = var.environment
      Project     = var.project_name
      SecretType  = each.value.type
    },
    each.value.tags
  )
}

# Secret Versions
resource "aws_secretsmanager_secret_version" "secrets" {
  for_each = local.secret_configs

  secret_id     = aws_secretsmanager_secret.secrets[each.key].id
  secret_string = jsonencode(each.value.secret_data)

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Lambda function for database rotation (if needed)
resource "aws_lambda_function" "rotation" {
  for_each = {
    for k, v in local.secret_configs : k => v
    if v.rotation_enabled && v.type == "database"
  }

  filename         = data.archive_file.rotation_lambda[each.key].output_path
  function_name    = "${var.project_name}-${var.environment}-${each.key}-rotation"
  role            = aws_iam_role.rotation[each.key].arn
  handler         = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.rotation_lambda[each.key].output_base64sha256
  runtime         = "python3.9"
  timeout         = 30

  environment {
    variables = {
      SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.${data.aws_region.current.name}.amazonaws.com"
    }
  }

  vpc_config {
    subnet_ids         = var.lambda_subnet_ids
    security_group_ids = var.lambda_security_group_ids
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-${each.key}-rotation"
  }
}

# Lambda deployment package for rotation
data "archive_file" "rotation_lambda" {
  for_each = {
    for k, v in local.secret_configs : k => v
    if v.rotation_enabled && v.type == "database"
  }

  type        = "zip"
  output_path = "/tmp/${var.project_name}-${var.environment}-${each.key}-rotation.zip"

  source {
    content = templatefile("${path.module}/rotation_lambda.py", {
      secret_arn    = aws_secretsmanager_secret.secrets[each.key].arn
      db_engine     = each.value.db_engine
      db_username   = each.value.db_username
      db_name       = each.value.db_name
    })
    filename = "lambda_function.py"
  }
}

# IAM role for Lambda rotation function
resource "aws_iam_role" "rotation" {
  for_each = {
    for k, v in local.secret_configs : k => v
    if v.rotation_enabled && v.type == "database"
  }

  name = "${var.project_name}-${var.environment}-${each.key}-rotation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-${each.key}-rotation-role"
  }
}

# IAM policy for Lambda rotation function
resource "aws_iam_role_policy" "rotation" {
  for_each = {
    for k, v in local.secret_configs : k => v
    if v.rotation_enabled && v.type == "database"
  }

  name = "${var.project_name}-${var.environment}-${each.key}-rotation-policy"
  role = aws_iam_role.rotation[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretVersionStage"
        ]
        Resource = aws_secretsmanager_secret.secrets[each.key].arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBClusters",
          "rds:DescribeDBInstances",
          "rds:ModifyDBInstance",
          "rds:ModifyDBCluster"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach basic execution role to Lambda
resource "aws_iam_role_policy_attachment" "rotation_basic" {
  for_each = {
    for k, v in local.secret_configs : k => v
    if v.rotation_enabled && v.type == "database"
  }

  role       = aws_iam_role.rotation[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Configure automatic rotation
resource "aws_secretsmanager_secret_rotation" "secrets" {
  for_each = {
    for k, v in local.secret_configs : k => v
    if v.rotation_enabled
  }

  secret_id           = aws_secretsmanager_secret.secrets[each.key].id
  rotation_lambda_arn = each.value.type == "database" ? aws_lambda_function.rotation[each.key].arn : null

  rotation_rules {
    automatically_after_days = each.value.rotation_days
  }

  depends_on = [aws_lambda_function.rotation]
}

# Lambda permission for Secrets Manager to invoke rotation function
resource "aws_lambda_permission" "rotation" {
  for_each = {
    for k, v in local.secret_configs : k => v
    if v.rotation_enabled && v.type == "database"
  }

  statement_id  = "AllowSecretsManagerInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotation[each.key].function_name
  principal     = "secretsmanager.amazonaws.com"
}

# Data source for current AWS region
data "aws_region" "current" {}

# IAM policy for applications to access secrets
resource "aws_iam_policy" "secrets_access" {
  name        = "${var.project_name}-${var.environment}-secrets-access"
  description = "Policy for accessing ${var.project_name} ${var.environment} secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [for secret in aws_secretsmanager_secret.secrets : secret.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = var.kms_key_arn
        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.${data.aws_region.current.name}.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-secrets-access"
  }
}

# IAM roles for different services
resource "aws_iam_role" "service_roles" {
  for_each = var.service_roles

  name = "${var.project_name}-${var.environment}-${each.key}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = each.value.service
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-${each.key}-role"
  }
}

# Attach secrets access policy to service roles
resource "aws_iam_role_policy_attachment" "service_secrets_access" {
  for_each = var.service_roles

  role       = aws_iam_role.service_roles[each.key].name
  policy_arn = aws_iam_policy.secrets_access.arn
}

# Additional policies for service roles
resource "aws_iam_role_policy_attachment" "service_additional_policies" {
  for_each = {
    for combination in flatten([
      for role_name, role_config in var.service_roles : [
        for policy_arn in role_config.additional_policies : {
          role_name  = role_name
          policy_arn = policy_arn
        }
      ]
    ]) : "${combination.role_name}-${basename(combination.policy_arn)}" => combination
  }

  role       = aws_iam_role.service_roles[each.value.role_name].name
  policy_arn = each.value.policy_arn
}