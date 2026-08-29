# trying this out because pod identity is not working
# for aws load balancer controller on fargate
module "aws_load_balancer_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "6.8.1"

  name                                   = "aws-load-balancer-controller"
  attach_load_balancer_controller_policy = true
  use_name_prefix                        = false
  oidc_providers = {
    this = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = var.tags
}
