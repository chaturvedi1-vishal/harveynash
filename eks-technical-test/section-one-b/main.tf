terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.60" }
  }
}

provider "aws" {
  region = "eu-west-1"
}

# Trust policy allowing only ops-alice from one IP
data "aws_iam_policy_document" "opsuser_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::1234566789001:user/ops-alice"]
    }
    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = ["52.94.236.248/32"]
    }
  }
}

resource "aws_iam_role" "opsuser" {
  name               = "OpsUser"
  assume_role_policy = data.aws_iam_policy_document.opsuser_trust.json
  tags               = { Project = "EKS-Tech-Test" }
}

output "opsuser_role_arn" {
  value = aws_iam_role.opsuser.arn
}
