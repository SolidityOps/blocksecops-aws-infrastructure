# Route Tables and Routing Configuration
# Separate route tables for public, private, and database subnets

# Route table for public subnets
resource "aws_route_table" "public" {
  count = length(local.selected_azs)

  vpc_id = aws_vpc.main.id

  # Route to Internet Gateway for internet access
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-rt-${count.index + 1}"
    Type = "route-table"
    Tier = "public"
    AZ   = local.selected_azs[count.index]
  })
}

# Route table for private subnets
resource "aws_route_table" "private" {
  count = length(local.selected_azs)

  vpc_id = aws_vpc.main.id

  # Route to NAT Gateway for internet access (if enabled)
  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[count.index].id
    }
  }

  # Route to NAT Instance for internet access (if using NAT instance)
  dynamic "route" {
    for_each = var.use_nat_instance && !var.enable_nat_gateway ? [1] : []
    content {
      cidr_block           = "0.0.0.0/0"
      network_interface_id = aws_instance.nat[count.index].primary_network_interface_id
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-rt-${count.index + 1}"
    Type = "route-table"
    Tier = "private"
    AZ   = local.selected_azs[count.index]
  })

  depends_on = [
    aws_nat_gateway.main,
    aws_instance.nat
  ]
}

# Route table for database subnets (separate from private for better isolation)
resource "aws_route_table" "database" {
  count = var.create_database_subnets ? length(local.selected_azs) : 0

  vpc_id = aws_vpc.main.id

  # Database subnets typically don't need internet access
  # Route to NAT Gateway only if explicitly enabled
  dynamic "route" {
    for_each = var.enable_nat_gateway && var.database_subnet_internet_access ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[count.index].id
    }
  }

  # Route to NAT Instance only if explicitly enabled and using NAT instance
  dynamic "route" {
    for_each = var.use_nat_instance && !var.enable_nat_gateway && var.database_subnet_internet_access ? [1] : []
    content {
      cidr_block           = "0.0.0.0/0"
      network_interface_id = aws_instance.nat[count.index].primary_network_interface_id
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-database-rt-${count.index + 1}"
    Type = "route-table"
    Tier = "database"
    AZ   = local.selected_azs[count.index]
  })
}

# Route table associations for public subnets
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[count.index].id
}

# Route table associations for private subnets
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Route table associations for database subnets
resource "aws_route_table_association" "database" {
  count = length(aws_subnet.database)

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database[count.index].id
}

# Network ACLs for additional security layer

# Network ACL for public subnets
resource "aws_network_acl" "public" {
  count = var.create_network_acls ? 1 : 0

  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.public[*].id

  # Inbound rules
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 22
    to_port    = 22
  }

  # Ephemeral ports for return traffic
  ingress {
    protocol   = "tcp"
    rule_no    = 130
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Outbound rules
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-nacl"
    Type = "network-acl"
    Tier = "public"
  })
}

# Network ACL for private subnets
resource "aws_network_acl" "private" {
  count = var.create_network_acls ? 1 : 0

  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.private[*].id

  # Inbound rules - allow traffic from VPC
  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 0
    to_port    = 0
  }

  # Ephemeral ports for return traffic from internet
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Outbound rules
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-nacl"
    Type = "network-acl"
    Tier = "private"
  })
}

# Network ACL for database subnets
resource "aws_network_acl" "database" {
  count = var.create_network_acls && var.create_database_subnets ? 1 : 0

  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.database[*].id

  # Inbound rules - allow traffic from all private subnets
  dynamic "ingress" {
    for_each = length(aws_subnet.private) > 0 ? [for i, subnet in aws_subnet.private : i] : []
    content {
      protocol   = "tcp"
      rule_no    = 100 + (ingress.value * 10)
      action     = "allow"
      cidr_block = aws_subnet.private[ingress.value].cidr_block
      from_port  = 5432
      to_port    = 5432
    }
  }

  # Redis port - allow traffic from all private subnets
  dynamic "ingress" {
    for_each = length(aws_subnet.private) > 0 ? [for i, subnet in aws_subnet.private : i] : []
    content {
      protocol   = "tcp"
      rule_no    = 150 + (ingress.value * 10)
      action     = "allow"
      cidr_block = aws_subnet.private[ingress.value].cidr_block
      from_port  = 6379
      to_port    = 6379
    }
  }


  # Ephemeral ports for return traffic
  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Outbound rules - minimal for database security
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  egress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-database-nacl"
    Type = "network-acl"
    Tier = "database"
  })
}