# Public tier: only load balancers and NAT gateways live here.
resource "aws_subnet" "public" {
  count = var.az_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.public_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  # Nothing in this design needs a public IP except the NAT EIPs,
  # which are attached explicitly.
  map_public_ip_on_launch = false

  tags = merge(local.tags, {
    Name = "${var.name}-public-${local.azs[count.index]}"
    Tier = "public"
  })
}

# Private tier: Jenkins controller, agents, EFS and application services.
# Outbound internet only, through NAT.
resource "aws_subnet" "private" {
  count = var.az_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.private_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(local.tags, {
    Name = "${var.name}-private-${local.azs[count.index]}"
    Tier = "private"
  })
}

# Database tier: no route to or from the internet at all.
resource "aws_subnet" "database" {
  count = length(local.database_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.database_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(local.tags, {
    Name = "${var.name}-database-${local.azs[count.index]}"
    Tier = "database"
  })
}

# Ready for a future RDS/Aurora instance: db_subnet_group_name = module.network.db_subnet_group_name
resource "aws_db_subnet_group" "this" {
  count = var.enable_database_subnets ? 1 : 0

  name        = "${var.name}-database"
  description = "Isolated database subnets for ${var.name}"
  subnet_ids  = aws_subnet.database[*].id

  tags = merge(local.tags, { Name = "${var.name}-database" })
}

resource "aws_elasticache_subnet_group" "this" {
  count = var.enable_database_subnets && var.create_elasticache_subnet_group ? 1 : 0

  name        = "${var.name}-cache"
  description = "Isolated cache subnets for ${var.name}"
  subnet_ids  = aws_subnet.database[*].id

  tags = merge(local.tags, { Name = "${var.name}-cache" })
}
