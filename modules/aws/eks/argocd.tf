data "http" "argocd_config" {
  url = "https://raw.githubusercontent.com/mlinfra-io/eks-resources/main/hub/projects/argocd/values.yaml"
}

resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "9.3.5"
  create_namespace = true
  values           = [data.http.argocd_config.response_body]

  depends_on = [
    module.eks,
    helm_release.karpenter,
    kubernetes_manifest.karpenter_ops_node_resources
  ]
}

data "http" "argocd_applications" {
  for_each = toset([
    "repository-secret.yaml",
    "helm-charts.yaml"
  ])

  url = "https://raw.githubusercontent.com/mlinfra-io/eks-resources/main/hub/projects/argocd/manifests/${each.value}"
}

resource "kubernetes_manifest" "argocd_applications" {
  for_each = data.http.argocd_applications

  manifest = yamldecode(each.value.response_body)

  computed_fields = [
    "metadata.labels",
    "metadata.annotations",
    "metadata.finalizers",
    "metadata.generation",
    "metadata.resourceVersion",
    "metadata.uid",
    "status",
    "stringData"
  ]

  depends_on = [
    helm_release.argocd
  ]
}
