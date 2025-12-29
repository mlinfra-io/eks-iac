module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.5.0"

  name = var.name
  cidr = var.cidr_block

  region                             = var.region
  azs                                = local.azs
  private_subnets                    = var.private_subnet_cidr
  public_subnets                     = var.public_subnet_cidr
  secondary_cidr_blocks              = var.secondary_cidr_block
  database_subnets                   = local.db_subnets
  create_database_subnet_group       = var.create_database_subnets
  create_database_subnet_route_table = var.create_database_subnets

  enable_vpn_gateway     = false
  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = var.one_nat_gateway_per_az ? false : true
  one_nat_gateway_per_az = var.one_nat_gateway_per_az

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_flow_log = var.enable_flow_log

  manage_default_network_acl = true

  tags = var.tags
}

module "flow_logs_bucket" {
  source = "../s3"

  name          = "vpc-flow-logs"
  region        = var.region
  force_destroy = true

  attach_access_log_delivery_policy = true
  attach_waf_log_delivery_policy    = true

  tags = var.tags
}

module "vpc_flow_logs" {
  source  = "terraform-aws-modules/vpc/aws//modules/flow-log"
  version = "~> 6.5.0"

  name   = "${module.vpc.name}-flow-logs"
  vpc_id = module.vpc.vpc_id

  log_destination_type = "s3"
  log_destination      = module.flow_logs_bucket.s3_bucket_arn

  tags = var.tags
}

module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 6.5.0"

  vpc_id = module.vpc.vpc_id

  create_security_group      = true
  security_group_name        = "${module.vpc.name}-vpc-endpoints"
  security_group_description = "${module.vpc.name} VPC endpoint security group"
  security_group_rules = {
    ingress_https = {
      description = "HTTPS from VPC"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  }

  endpoints = {
    s3 = {
      service             = "s3"
      private_dns_enabled = true
      dns_options = {
        private_dns_only_for_inbound_resolver_endpoint = false
      }
      tags = { Name = "s3-vpc-endpoint" }
    },
    ecr_dkr = {
      service             = "ecr.dkr"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    },
    rds = {
      service             = "rds"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    },
  }

  tags = var.tags
}
