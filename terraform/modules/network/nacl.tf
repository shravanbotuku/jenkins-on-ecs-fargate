# Public and private tiers keep the default NACL: security groups do the
# filtering there, and stateless NACL rules for ALB/NAT traffic add risk
# without adding much protection.
#
# The database tier is the exception. Its NACL is a second layer behind the
# per-environment database security groups:
#   - inbound: only the database ports, only from the private (app) subnets
#   - outbound: only replies (ephemeral ports) back to the private subnets
# The public tier can never reach a database, even if a security group is
# misconfigured.

locals {
  db_ingress_rules = {
    for pair in setproduct(var.database_ports, local.private_subnet_cidrs) :
    "${pair[0]}-${pair[1]}" => { port = pair[0], cidr = pair[1] }
  }
}

resource "aws_network_acl" "database" {
  count = var.enable_database_subnets ? 1 : 0

  vpc_id     = aws_vpc.this.id
  subnet_ids = aws_subnet.database[*].id

  tags = merge(local.tags, { Name = "${var.name}-database", Tier = "database" })
}

resource "aws_network_acl_rule" "database_ingress" {
  # Rule numbers are derived from the sorted keys so they stay stable.
  for_each = var.enable_database_subnets ? local.db_ingress_rules : {}

  network_acl_id = aws_network_acl.database[0].id
  rule_number    = 100 + index(sort(keys(local.db_ingress_rules)), each.key)
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = each.value.cidr
  from_port      = each.value.port
  to_port        = each.value.port
}

resource "aws_network_acl_rule" "database_egress" {
  count = var.enable_database_subnets ? length(local.private_subnet_cidrs) : 0

  network_acl_id = aws_network_acl.database[0].id
  rule_number    = 100 + count.index
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = local.private_subnet_cidrs[count.index]
  from_port      = 1024
  to_port        = 65535
}
