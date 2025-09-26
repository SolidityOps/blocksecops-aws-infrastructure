# Subnet Configuration for Single-AZ MVP Deployment
# Public and private subnets in a single availability zone

# Get availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Public subnet for load balancers and NAT gateway
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name                     = "${var.environment}-solidity-security-public-subnet"
    Environment              = var.environment
    Type                     = "public"
    "kubernetes.io/role/elb" = "1"
  })
}

# Private subnet for EKS nodes, RDS, and ElastiCache
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = merge(var.common_tags, {
    Name                              = "${var.environment}-solidity-security-private-subnet"
    Environment                       = var.environment
    Type                              = "private"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

# NAT Gateway for private subnet internet access
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  depends_on = [aws_internet_gateway.main]

  tags = merge(var.common_tags, {
    Name        = "${var.environment}-solidity-security-nat-gateway"
    Environment = var.environment
  })
}