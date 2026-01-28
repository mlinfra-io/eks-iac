module "eks_kms_key" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 4.1.0"

  description             = "KMS Key for EKS Secrets encryption"
  aliases                 = ["${var.cluster_name}-secrets-encryption-key"]
  deletion_window_in_days = var.deletion_window_in_days

  tags = var.tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.15.1"

  name               = var.cluster_name
  kubernetes_version = var.k8s_version

  vpc_id                   = var.vpc_id
  subnet_ids               = var.subnet_ids
  ip_family                = var.cluster_ip_family
  control_plane_subnet_ids = var.subnet_ids

  endpoint_private_access                  = var.cluster_endpoint_private_access
  endpoint_public_access                   = var.cluster_endpoint_public_access
  enable_cluster_creator_admin_permissions = true
  enable_irsa                              = true
  create_kms_key                           = false
  encryption_config = {
    provider_key_arn = module.eks_kms_key.key_arn
    resources        = ["secrets"]
  }

  addons = local.eks_addons

  security_group_additional_rules      = var.cluster_security_group_additional_rules
  node_security_group_additional_rules = var.node_security_group_additional_rules

  enable_auto_mode_custom_tags = false

  fargate_profiles = {
    coredns = {
      name                     = "coredns"
      iam_role_name            = "${var.cluster_name}-fg-coredns"
      iam_role_use_name_prefix = false
      selectors = [
        {
          namespace = "kube-system"
          labels = {
            "k8s-app" = "kube-dns"
          }
        }
      ]
    }
    karpenter = {
      name                     = "karpenter"
      iam_role_name            = "${var.cluster_name}-fg-karpenter"
      iam_role_use_name_prefix = false
      selectors = [
        {
          namespace = "kube-system"
          labels = {
            "app.kubernetes.io/name" = "karpenter"
          }
        }
      ]
    }
  }

  node_security_group_tags = merge(var.tags, {
    "karpenter.sh/discovery" = var.cluster_name
  })

  enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  tags              = var.tags
}
