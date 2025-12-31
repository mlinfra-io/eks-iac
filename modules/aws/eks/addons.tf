locals {
  eks_addons = {
    eks-pod-identity-agent = {
      before_compute = true
    }
    vpc-cni = {
      # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
      before_compute = var.vpc_cni_addon.before_compute
      # most_recent                 = var.vpc_cni_addon.most_recent
      resolve_conflicts_on_create = var.vpc_cni_addon.resolve_conflicts_on_create
      resolve_conflicts_on_update = var.vpc_cni_addon.resolve_conflicts_on_update
      configuration_values        = jsonencode(var.vpc_cni_addon_configuration_values)
    }
    coredns = {
      # most_recent                 = var.coredns_addon.most_recent
      resolve_conflicts_on_create = var.coredns_addon.resolve_conflicts_on_create
      resolve_conflicts_on_update = var.coredns_addon.resolve_conflicts_on_update
      # configuration_values        = jsonencode(var.coredns_addon_configuration_values)
    }
    kube-proxy = {
      # most_recent                 = true
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "PRESERVE"
    }
    # create ebs csi driver later on..
    # aws-ebs-csi-driver = {
    #   # most_recent                 = var.ebs_csi_driver_addon.most_recent
    #   resolve_conflicts_on_create = var.ebs_csi_driver_addon.resolve_conflicts_on_create
    #   resolve_conflicts_on_update = var.ebs_csi_driver_addon.resolve_conflicts_on_update
    #   configuration_values        = jsonencode(var.ebs_csi_driver_addon_configuration_values)
    # }
  }
}
