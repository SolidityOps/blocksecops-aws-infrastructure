# VPC Endpoints for AWS Services
# Reduces internet egress costs and improves security
#
# NOTE: Single-AZ MVP Design Decision
# All interface endpoints use a single private subnet for cost optimization
# in the MVP phase. Production upgrade path includes multi-AZ deployment
# with VPC endpoints distributed across multiple subnets for high availability.

# S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = merge(var.common_tags, {
    Name        = "${var.environment}-solidity-security-s3-endpoint"
    Environment = var.environment
    Service     = "S3"
  })
}

# ECR API Interface Endpoint
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.common_tags, {
    Name        = "${var.environment}-solidity-security-ecr-api-endpoint"
    Environment = var.environment
    Service     = "ECR"
  })
}

# ECR Docker Interface Endpoint
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.common_tags, {
    Name        = "${var.environment}-solidity-security-ecr-dkr-endpoint"
    Environment = var.environment
    Service     = "ECR"
  })
}

# Secrets Manager Interface Endpoint
resource "aws_vpc_endpoint" "secrets_manager" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.common_tags, {
    Name        = "${var.environment}-solidity-security-secrets-manager-endpoint"
    Environment = var.environment
    Service     = "SecretsManager"
  })
}

# CloudWatch Logs Interface Endpoint
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.common_tags, {
    Name        = "${var.environment}-solidity-security-logs-endpoint"
    Environment = var.environment
    Service     = "CloudWatchLogs"
  })
}

# CloudWatch Monitoring Interface Endpoint
resource "aws_vpc_endpoint" "monitoring" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.monitoring"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.common_tags, {
    Name        = "${var.environment}-solidity-security-monitoring-endpoint"
    Environment = var.environment
    Service     = "CloudWatch"
  })
}

# Security Group for VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.environment}-solidity-security-vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS access from EKS nodes"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name        = "${var.environment}-solidity-security-vpc-endpoints-sg"
    Environment = var.environment
    Service     = "VPC-Endpoints"
  })
}