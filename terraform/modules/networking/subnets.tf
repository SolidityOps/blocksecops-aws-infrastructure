# Subnet configuration for VPC
# Single-AZ deployment for MVP with public and private subnets

# Public subnets for load balancers and NAT gateways
resource "aws_subnet" "public" {
  count = length(local.selected_azs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, var.subnet_bits, count.index)
  availability_zone       = local.selected_azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-subnet-${count.index + 1}"
    Type = "public-subnet"
    AZ   = local.selected_azs[count.index]
    Tier = "public"
    # Kubernetes tags for load balancer discovery
    "kubernetes.io/cluster/${local.name_prefix}-cluster" = "shared"
    "kubernetes.io/role/elb"                             = "1"
  })
}

# Private subnets for EKS nodes, databases, and application services
resource "aws_subnet" "private" {
  count = length(local.selected_azs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, var.subnet_bits, count.index + length(local.selected_azs))
  availability_zone = local.selected_azs[count.index]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-subnet-${count.index + 1}"
    Type = "private-subnet"
    AZ   = local.selected_azs[count.index]
    Tier = "private"
    # Kubernetes tags for internal load balancer discovery
    "kubernetes.io/cluster/${local.name_prefix}-cluster" = "shared"
    "kubernetes.io/role/internal-elb"                    = "1"
  })
}

# Database subnets for RDS and ElastiCache (separate from EKS)
resource "aws_subnet" "database" {
  count = var.create_database_subnets ? length(local.selected_azs) : 0

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, var.subnet_bits, count.index + (2 * length(local.selected_azs)))
  availability_zone = local.selected_azs[count.index]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-database-subnet-${count.index + 1}"
    Type = "database-subnet"
    AZ   = local.selected_azs[count.index]
    Tier = "database"
  })
}

# DB Subnet Group for RDS instances
resource "aws_db_subnet_group" "main" {
  count = var.create_database_subnets ? 1 : 0

  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-db-subnet-group"
    Type = "db-subnet-group"
  })
}

# ElastiCache Subnet Group for Redis/Memcached
resource "aws_elasticache_subnet_group" "main" {
  count = var.create_database_subnets ? 1 : 0

  name       = "${local.name_prefix}-cache-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-cache-subnet-group"
    Type = "cache-subnet-group"
  })
}