terraform {
  # 1.10+ is needed for S3 native state locking (use_lockfile) in the roots.
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0, < 7.0"
    }
  }
}
