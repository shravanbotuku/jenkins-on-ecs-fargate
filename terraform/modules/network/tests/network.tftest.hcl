# Unit tests for the network module. They run `terraform plan` against a
# mocked AWS provider, so they need no AWS account or credentials:
#   terraform init -backend=false && terraform test

mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = ["us-east-1a", "us-east-1b", "us-east-1c"]
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "111111111111"
    }
  }

  # IAM policy documents must render valid JSON for the role resources.
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  name = "test"
}

run "defaults_two_azs_single_nat" {
  command = plan

  assert {
    condition     = aws_subnet.public[*].cidr_block == ["10.20.0.0/24", "10.20.1.0/24"]
    error_message = "Public subnets should be the first two /24s."
  }

  assert {
    condition     = aws_subnet.private[*].cidr_block == ["10.20.16.0/22", "10.20.20.0/22"]
    error_message = "Private subnets should be /22s starting at 10.20.16.0."
  }

  assert {
    condition     = aws_subnet.database[*].cidr_block == ["10.20.32.0/24", "10.20.33.0/24"]
    error_message = "Database subnets should be /24s starting at 10.20.32.0."
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 1 && length(aws_route_table.private) == 1
    error_message = "single_nat_gateway should create one NAT and one private route table."
  }

  assert {
    condition     = alltrue([for s in aws_subnet.public : s.map_public_ip_on_launch == false])
    error_message = "Public subnets must not auto-assign public IPs."
  }

  assert {
    condition     = length(aws_db_subnet_group.this) == 1
    error_message = "The RDS subnet group should exist by default."
  }

  assert {
    condition     = length(aws_vpc_endpoint.interface) == 0
    error_message = "Interface endpoints must be opt-in."
  }

  assert {
    condition     = length(aws_flow_log.this) == 1 && aws_flow_log.this[0].traffic_type == "ALL"
    error_message = "Flow logs should be on and capture all traffic."
  }
}

run "database_tier_has_no_internet_route" {
  command = plan

  # Routes are separate aws_route resources. The only ones that exist are the
  # public IGW route and one NAT route per private route table, so the
  # database route table keeps just the implicit local route.
  assert {
    condition     = length(aws_route.private_nat) == length(aws_route_table.private) && length(aws_route_table.database) == 1
    error_message = "Only public and private route tables may carry 0.0.0.0/0 routes."
  }

  assert {
    condition     = length(aws_route_table_association.database) == 2
    error_message = "Both database subnets should use the isolated database route table."
  }

  # 3 ports x 2 private subnets = 6 inbound rules, all scoped to private subnet CIDRs.
  assert {
    condition     = length(aws_network_acl_rule.database_ingress) == 6
    error_message = "Database NACL should allow each DB port from each private subnet only."
  }

  assert {
    condition = alltrue([
      for r in aws_network_acl_rule.database_ingress :
      contains(["10.20.16.0/22", "10.20.20.0/22"], r.cidr_block)
    ])
    error_message = "Database NACL ingress must only allow the private subnets."
  }
}

run "three_azs_nat_per_az" {
  command = plan

  variables {
    az_count           = 3
    single_nat_gateway = false
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 3 && length(aws_route_table.private) == 3
    error_message = "One NAT and one private route table per AZ expected."
  }

  assert {
    condition     = aws_subnet.private[2].cidr_block == "10.20.24.0/22"
    error_message = "Third private subnet should be 10.20.24.0/22."
  }
}

run "optional_tiers_off" {
  command = plan

  variables {
    enable_database_subnets    = false
    enable_flow_logs           = false
    enable_interface_endpoints = false
  }

  assert {
    condition     = length(aws_subnet.database) == 0 && length(aws_network_acl.database) == 0
    error_message = "Disabling the database tier should remove its subnets and NACL."
  }

  assert {
    condition     = output.db_subnet_group_name == null
    error_message = "db_subnet_group_name should be null when the tier is off."
  }
}

run "rejects_non_slash_16" {
  command = plan

  variables {
    vpc_cidr = "10.20.0.0/20"
  }

  expect_failures = [var.vpc_cidr]
}
