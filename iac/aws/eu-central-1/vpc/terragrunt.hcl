include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

include "env" {
  path   = find_in_parent_folders("env.hcl")
  expose = true
}

locals {
  name = "prod-vpc"
}

generate "provider_aws" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_version = "${include.root.locals.terraform_version}"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "${include.root.locals.aws_provider_version}"
    }
  }
}
provider "aws" {
  region = "${include.env.locals.region}"
}
EOF
}

inputs = {
  name   = local.name
  region = include.env.locals.region
}

terraform {
  source = "${get_repo_root()}/modules/aws//vpc"
}
