output "karpenter_iam_role_name" {
  value = module.karpenter_dependencies.iam_role_name
}

output "karpenter_node_iam_role_name" {
  value = module.karpenter_dependencies.node_iam_role_name
}
