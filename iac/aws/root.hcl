locals {
  aws_provider_version = "~> 6.28.0"
  terraform_version    = ">= 1.14.0"
  region               = "eu-central-1"
  state_bucket_name    = "mlinfra-prod-eks-iac"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "skip"
  contents  = <<EOF
terraform {
  required_version = "${local.terraform_version}"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "${local.aws_provider_version}"
    }
  }
}
provider "aws" {
  region = local.region
}
EOF
}

remote_state {
  backend = "s3"
  config = {
    encrypt      = true
    bucket       = local.state_bucket_name
    key          = "${basename(get_repo_root())}/${path_relative_to_include()}/terraform.tfstate"
    region       = local.region
    use_lockfile = true
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
