data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# Only zones that need no opt-in, so the module works in any account.
# Used only when var.availability_zones is not set.
data "aws_availability_zones" "available" {
  #checkov:skip=CKV_AWS_394:Result is sliced to az_count, and callers can pin exact zones with var.availability_zones.
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  # Pinned zones win; otherwise take the first az_count available zones.
  azs = var.availability_zones != null ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # Fixed layout inside the /16 (example values for 10.20.0.0/16):
  #   public   /24 at index 0..2   -> 10.20.0.0/24,  10.20.1.0/24,  10.20.2.0/24
  #   private  /22 at index 4..6   -> 10.20.16.0/22, 10.20.20.0/22, 10.20.24.0/22
  #   database /24 at index 32..34 -> 10.20.32.0/24, 10.20.33.0/24, 10.20.34.0/24
  # Private subnets are larger because every Fargate task (controller, agents,
  # services) takes one IP. The gaps leave room for new tiers later.
  public_subnet_cidrs   = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, i)]
  private_subnet_cidrs  = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 6, 4 + i)]
  database_subnet_cidrs = var.enable_database_subnets ? [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, 32 + i)] : []

  nat_count = var.single_nat_gateway ? 1 : var.az_count

  tags = merge(var.tags, { Module = "network" })
}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  # Both are needed for Cloud Map private DNS, EFS mount names and
  # interface endpoints with private DNS.
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.tags, { Name = "${var.name}-vpc" })
}

# Take over the default security group and remove all its rules, so nothing
# can be launched into an open-by-default group by accident.
resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.tags, { Name = "${var.name}-default-sg-do-not-use" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.tags, { Name = "${var.name}-igw" })
}
