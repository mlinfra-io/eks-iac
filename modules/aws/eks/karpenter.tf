data "aws_iam_policy_document" "karpenter_controller_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"
      values   = ["system:serviceaccount:kube-system:karpenter"]
    }

    # https://aws.amazon.com/premiumsupport/knowledge-center/eks-troubleshoot-oidc-and-irsa/?nc1=h_ls
    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]
  }
}

module "karpenter_dependencies" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 21.15.1"

  # we are using module.eks.cluster_name here instead of var.cluster_name as
  # we want the cluster to be created before the pod identity association
  cluster_name = module.eks.cluster_name

  # Name needs to match role name passed to the EC2NodeClass
  node_iam_role_use_name_prefix   = false
  node_iam_role_name              = "${module.eks.cluster_name}-karpenter-node"
  node_iam_role_attach_cni_policy = true
  create_pod_identity_association = false

  # Used to attach additional IAM policies to the Karpenter node IAM role
  node_iam_role_additional_policies = {
    AmazonEKSWorkerNodePolicy    = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
  iam_role_source_assume_policy_documents = [
    data.aws_iam_policy_document.karpenter_controller_assume_role_policy.json,
  ]
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
    value = module.karpenter_dependencies.queue_name
    }, {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter_dependencies.iam_role_arn
    }
  ]

  depends_on = [
    module.karpenter_dependencies
  ]
}

data "http" "karpenter_manifests" {
  for_each = toset([
    "nodeclass.yml",
    "nodepool.yml"
  ])

  url = "https://raw.githubusercontent.com/mlinfra-io/eks-resources/main/hub/karpenter/manifests/${each.value}"
}

resource "kubernetes_manifest" "karpenter_ops_node_resources" {
  for_each = data.http.karpenter_manifests

  manifest = yamldecode(each.value.response_body)

  computed_fields = [
    "metadata.labels",
    "metadata.annotations",
    "metadata.finalizers",
    "metadata.generation",
    "metadata.resourceVersion",
    "metadata.uid",
    "status"
  ]

  depends_on = [
    helm_release.karpenter
  ]
}
