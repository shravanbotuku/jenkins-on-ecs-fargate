output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "azs" {
  description = "Availability zones used, in subnet order."
  value       = local.azs
}

output "public_subnet_ids" {
  description = "Public subnet IDs (load balancers, NAT)."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs (Jenkins, agents, EFS, app services)."
  value       = aws_subnet.private[*].id
}

output "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks."
  value       = aws_subnet.private[*].cidr_block
}

output "database_subnet_ids" {
  description = "Isolated database subnet IDs (empty when the tier is disabled)."
  value       = aws_subnet.database[*].id
}

output "database_subnet_cidrs" {
  description = "Database subnet CIDR blocks."
  value       = aws_subnet.database[*].cidr_block
}

output "db_subnet_group_name" {
  description = "RDS subnet group name, or null when the database tier is disabled."
  value       = one(aws_db_subnet_group.this[*].name)
}

output "elasticache_subnet_group_name" {
  description = "ElastiCache subnet group name, or null when not created."
  value       = one(aws_elasticache_subnet_group.this[*].name)
}

output "public_route_table_id" {
  description = "Public route table ID."
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "Private route table IDs (one per NAT gateway)."
  value       = aws_route_table.private[*].id
}

output "database_route_table_id" {
  description = "Database route table ID, or null when the tier is disabled."
  value       = one(aws_route_table.database[*].id)
}

output "nat_public_ips" {
  description = "Public IPs of the NAT gateways (useful for allow-lists on third-party APIs)."
  value       = aws_eip.nat[*].public_ip
}

output "endpoints_security_group_id" {
  description = "Security group of the interface endpoints, or null when they are disabled."
  value       = one(aws_security_group.endpoints[*].id)
}

output "flow_log_group_name" {
  description = "CloudWatch log group receiving VPC Flow Logs, or null when disabled."
  value       = one(aws_cloudwatch_log_group.flow_logs[*].name)
}
