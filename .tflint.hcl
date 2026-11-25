# Shared tflint config for every module and root.
# Run from a module folder with: tflint --config "$(git rev-parse --show-toplevel)/.tflint.hcl"
config {
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  preset  = "all"
}

plugin "aws" {
  enabled = true
  version = "0.50.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}
