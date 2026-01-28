output "karpenter_iam_role_name" {
  value = module.karpenter_dependencies.iam_role_name
}

output "karpenter_node_iam_role_name" {
  value = module.karpenter_dependencies.node_iam_role_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  value     = module.eks.cluster_certificate_authority_data
  sensitive = true
}

output "cluster_name" {
  value = module.eks.cluster_name
}
