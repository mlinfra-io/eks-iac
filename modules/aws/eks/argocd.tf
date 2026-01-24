data "http" "argocd_config" {
  url = "https://raw.githubusercontent.com/mlinfra-io/eks-resources/main/hub/argocd/helm/values.yml"
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
    kubernetes_manifest.karpenter_ops_node_resources
  ]
}
