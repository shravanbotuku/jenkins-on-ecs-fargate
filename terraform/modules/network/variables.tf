variable "name" {
  description = "Name prefix for every resource, e.g. \"platform\"."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}$", var.name))
    error_message = "name must be 2-21 lowercase letters, digits or hyphens, starting with a letter."
  }
}

variable "vpc_cidr" {
  description = "VPC CIDR block. Must be a /16; subnets are carved from it with a fixed layout (see README)."
  type        = string
  default     = "10.20.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0)) && endswith(var.vpc_cidr, "/16")
    error_message = "vpc_cidr must be a valid /16 CIDR block."
  }
}

variable "az_count" {
  description = "Number of availability zones to spread subnets across (2 or 3)."
  type        = number
  default     = 2

  validation {
    condition     = contains([2, 3], var.az_count)
    error_message = "az_count must be 2 or 3."
  }
}

variable "availability_zones" {
  description = "Optional exact zone names to use (e.g. [\"us-east-1a\", \"us-east-1b\"]). Length must equal az_count. null picks the first az_count available zones."
  type        = list(string)
  default     = null

  validation {
    condition     = var.availability_zones == null || length(coalesce(var.availability_zones, [])) == var.az_count
    error_message = "availability_zones must have exactly az_count entries."
  }
}

variable "single_nat_gateway" {
  description = "true = one NAT gateway shared by all AZs (cheaper, single point of failure). false = one NAT per AZ."
  type        = bool
  default     = true
}

variable "enable_database_subnets" {
  description = "Create the isolated database subnet tier (no internet route) and an RDS subnet group."
  type        = bool
  default     = true
}

variable "create_elasticache_subnet_group" {
  description = "Also create an ElastiCache subnet group on the database subnets."
  type        = bool
  default     = false
}

variable "database_ports" {
  description = "TCP ports the database NACL accepts from the private (app) subnets."
  type        = list(number)
  default     = [5432, 3306, 6379]

  validation {
    condition     = alltrue([for p in var.database_ports : p > 0 && p < 65536])
    error_message = "database_ports must be valid TCP ports."
  }
}

variable "enable_interface_endpoints" {
  description = "Create interface VPC endpoints (billed per hour per AZ). The S3 gateway endpoint is always created because it is free."
  type        = bool
  default     = false
}

variable "interface_endpoints" {
  description = "AWS service short names for interface endpoints, used when enable_interface_endpoints is true."
  type        = list(string)
  default     = ["ecr.api", "ecr.dkr", "logs", "secretsmanager", "sts", "ecs"]
}

variable "enable_flow_logs" {
  description = "Send VPC Flow Logs (all traffic) to CloudWatch Logs."
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "Retention for the flow log group, in days."
  type        = number
  default     = 365
}

variable "flow_log_kms_key_arn" {
  description = "KMS key ARN to encrypt the flow log group. The root passes the platform key; null uses CloudWatch's default encryption."
  type        = string
  default     = null
}

variable "tags" {
  description = "Extra tags merged onto every resource (the provider's default_tags still apply)."
  type        = map(string)
  default     = {}
}
