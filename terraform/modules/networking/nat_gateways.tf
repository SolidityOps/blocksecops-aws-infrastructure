# NAT Gateways for secure private subnet internet access
# Single NAT gateway for MVP cost optimization

# NAT Gateways for private subnet internet connectivity
resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? length(local.selected_azs) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  depends_on = [aws_internet_gateway.main]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nat-gateway-${count.index + 1}"
    Type = "nat-gateway"
    AZ   = local.selected_azs[count.index]
  })
}

# NAT Instance as cost-effective alternative (optional)
resource "aws_instance" "nat" {
  count = var.use_nat_instance && !var.enable_nat_gateway ? length(local.selected_azs) : 0

  ami                         = var.nat_instance_ami != "" ? var.nat_instance_ami : try(data.aws_ami.nat_instance[0].id, null)
  instance_type               = var.nat_instance_type
  subnet_id                   = aws_subnet.public[count.index].id
  associate_public_ip_address = true
  source_dest_check           = false

  vpc_security_group_ids = [aws_security_group.nat_instance[0].id]

  user_data = base64encode(templatefile("${path.module}/templates/nat_instance_userdata.sh", {
    vpc_cidr = var.vpc_cidr
  }))

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nat-instance-${count.index + 1}"
    Type = "nat-instance"
    AZ   = local.selected_azs[count.index]
  })

  lifecycle {
    ignore_changes = [user_data]
  }
}

# Security Group for NAT Instance
resource "aws_security_group" "nat_instance" {
  count = var.use_nat_instance && !var.enable_nat_gateway ? 1 : 0

  name_prefix = "${local.name_prefix}-nat-instance-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for NAT instance"

  # HTTP traffic from private subnets
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = aws_subnet.private[*].cidr_block
    description = "HTTP from private subnets"
  }

  # HTTPS traffic from private subnets
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = aws_subnet.private[*].cidr_block
    description = "HTTPS from private subnets"
  }

  # DNS traffic from private subnets
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = aws_subnet.private[*].cidr_block
    description = "DNS TCP from private subnets"
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = aws_subnet.private[*].cidr_block
    description = "DNS UDP from private subnets"
  }

  # SSH access for management (optional)
  dynamic "ingress" {
    for_each = var.nat_instance_ssh_allowed_cidr_blocks
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
      description = "SSH access for management"
    }
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nat-instance-sg"
    Type = "security-group"
    Role = "nat-instance"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Data source for NAT instance AMI
data "aws_ami" "nat_instance" {
  count = var.use_nat_instance && !var.enable_nat_gateway && var.nat_instance_ami == "" ? 1 : 0

  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-vpc-nat-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}