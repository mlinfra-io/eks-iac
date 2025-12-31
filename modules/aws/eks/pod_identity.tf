module "aws_vpc_cni_ipv4_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.6.0"

  name = "aws-vpc-cni-ipv4"

  attach_aws_vpc_cni_policy = true
  aws_vpc_cni_enable_ipv4   = true

  associations = {
    this = {
      cluster_name    = var.cluster_name
      namespace       = "kube-system"
      service_account = "aws-node"
    }
  }

  tags = var.tags
}

module "aws_ebs_csi_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.6.0"

  name = "aws-ebs-csi"

  attach_aws_ebs_csi_policy = true

  associations = {
    this = {
      cluster_name    = var.cluster_name
      namespace       = "kube-system"
      service_account = "ebs-csi-controller-sa"
    }
  }

  tags = var.tags
}
