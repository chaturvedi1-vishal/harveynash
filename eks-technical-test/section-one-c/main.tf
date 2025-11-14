terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.60" }
  }
}

provider "aws" {
  region = "eu-west-1"
}

variable "cluster_name" { default = "orders-eks" }
variable "oidc_provider_arn" {}
variable "oidc_provider_url" {}

locals {
  sa_namespace = "orders"
  sa_name      = "order-processor"
  bucket_name  = "incoming-orders"
}

# ---- Trust policy linking to EKS service account ----
data "aws_iam_policy_document" "irsa_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${local.sa_namespace}:${local.sa_name}"]
    }
  }
}

resource "aws_iam_role" "order_reader" {
  name               = "orders-reader-irsa"
  assume_role_policy = data.aws_iam_policy_document.irsa_trust.json
  tags               = { Project = "EKS-Tech-Test" }
}

# ---- S3 read policy ----
data "aws_iam_policy_document" "s3_read" {
  statement {
    effect = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${local.bucket_name}"]
  }
  statement {
    effect = "Allow"
    actions   = ["s3:GetObject", "s3:GetObjectVersion"]
    resources = ["arn:aws:s3:::${local.bucket_name}/*"]
  }
}

resource "aws_iam_policy" "s3_read" {
  name   = "incoming-orders-read"
  policy = data.aws_iam_policy_document.s3_read.json
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.order_reader.name
  policy_arn = aws_iam_policy.s3_read.arn
}

output "irsa_role_arn" {
  value = aws_iam_role.order_reader.arn
}