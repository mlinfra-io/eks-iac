module "karpenter_dependencies" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 21.12.0"

  # we are using module.eks.cluster_name here instead of var.cluster_name as
  # we want the cluster to be created before the pod identity association
  cluster_name = module.eks.cluster_name

  # Name needs to match role name passed to the EC2NodeClass
  node_iam_role_use_name_prefix   = false
  node_iam_role_name              = module.eks.cluster_name
  create_pod_identity_association = true

  # Used to attach additional IAM policies to the Karpenter node IAM role
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}

resource "helm_release" "karpenter" {
  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  namespace  = "kube-system"
  version    = "1.8.5"

  set = [{
    name  = "settings.clusterName"
    value = module.eks.cluster_name
    }, {
    name  = "settings.interruptionQueue"
    value = module.eks.cluster_name
    }, {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter_dependencies.iam_role_arn
    }
  ]

  depends_on = [
    module.karpenter_dependencies
  ]
}
