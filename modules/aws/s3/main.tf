module "s3" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.0"

  bucket        = var.name
  force_destroy = var.force_destroy
  region        = var.region

  attach_waf_log_delivery_policy    = var.attach_waf_log_delivery_policy
  attach_access_log_delivery_policy = var.attach_access_log_delivery_policy

  tags = var.tags
}
