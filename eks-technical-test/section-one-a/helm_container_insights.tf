resource "helm_release" "cloudwatch_agent" {
  name             = "cloudwatch-agent"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "cloudwatch-agent"
  namespace        = "amazon-cloudwatch"
  create_namespace = true
}
