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
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "karpenter.sh/discovery"          = "mlinfra-eks-cluster"
  }
  default_security_group_tags = {
    "kubernetes.io/cluster/mlinfra-eks-cluster" = "owned"
  }
}

terraform {
  source = "${get_repo_root()}/modules/aws//vpc"
}
