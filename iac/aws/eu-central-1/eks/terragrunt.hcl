include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

include "env" {
  path   = find_in_parent_folders("env.hcl")
  expose = true
}

dependency "vpc" {
  config_path                             = "${get_parent_terragrunt_dir("env")}/vpc"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs = {
    vpc_id                  = "some_id"
    vpc_public_subnets_ids  = ["some-id"]
    vpc_private_subnets_ids = ["some-id"]
  }
}

locals {
  cluster_name = "mlinfra-eks-cluster"
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
    helm = {
      source  = "hashicorp/helm"
      version = "${include.root.locals.helm_provider_version}"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "${include.root.locals.kubernetes_provider_version}"
    }
  }
}
provider "aws" {
  region = "${include.env.locals.region}"
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}
EOF
}

inputs = {
  cluster_name = local.cluster_name
  k8s_version  = "1.35"
  region       = include.env.locals.region
  vpc_id       = dependency.vpc.outputs.vpc_id
  subnet_ids   = dependency.vpc.outputs.vpc_private_subnets_ids
}

terraform {
  source = "${get_repo_root()}/modules/aws//eks"
  # source = ""
}
