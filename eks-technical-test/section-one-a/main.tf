provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

# -------------------------
# VPC (3 AZs, resilient)
# -------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.7"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = [for i in range(3) : cidrsubnet(var.vpc_cidr, 4, i)]
  public_subnets  = [for i in range(3) : cidrsubnet(var.vpc_cidr, 4, i + 8)]

  enable_nat_gateway   = true
  single_nat_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = var.tags
}

# -------------------------
# EKS Cluster
# -------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.11"

  cluster_name                    = var.cluster_name
  cluster_version                 = var.k8s_version
  vpc_id                          = module.vpc.vpc_id
  subnet_ids                      = module.vpc.private_subnets
  cluster_endpoint_public_access  = true
  enable_irsa                     = true

  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  cluster_addons = {
    vpc-cni = {
      most_recent = true
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
    coredns   = { most_recent = true }
    kube-proxy = { most_recent = true }
  }

  # -------------------------
  # Node group: 28 GB usable memory per node
  # -------------------------
  eks_managed_node_groups = {
    general = {
      instance_types = ["m6i.2xlarge"]  # 8 vCPU, 32 GiB
      desired_size   = 6
      min_size       = 3
      max_size       = 9
      ami_type       = "AL2_x86_64"
      subnet_ids     = module.vpc.private_subnets

      labels = { workload = "general" }

      # Reserve ~2-3GB for system/kube, leaving ~28GB usable
      bootstrap_extra_args = "--kube-reserved=cpu=500m,memory=1Gi --system-reserved=cpu=500m,memory=1Gi --eviction-hard=memory.available<500Mi"

      tags = {
        "k8s.io/cluster-autoscaler/enabled" = "true"
        "k8s.io/cluster-autoscaler/${var.cluster_name}" = "true"
      }
    }
  }

  tags = var.tags
}

# -------------------------
# CloudWatch log group for app logs
# -------------------------
resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/containerinsights/${var.cluster_name}/application"
  retention_in_days = 30
  tags              = var.tags
}
