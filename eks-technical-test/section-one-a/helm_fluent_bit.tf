resource "helm_release" "fluent_bit" {
  name             = "aws-for-fluent-bit"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-for-fluent-bit"
  namespace        = "amazon-cloudwatch"
  create_namespace = true

  set {
    name  = "cloudWatch.enabled"
    value = "true"
  }
  set {
    name  = "cloudWatch.logGroupName"
    value = "/aws/containerinsights/${var.cluster_name}/application"
  }
  set {
    name  = "cloudWatch.logRetentionDays"
    value = "30"
  }
}
