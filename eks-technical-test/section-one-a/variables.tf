variable "region"       { default = "eu-west-1" }
variable "cluster_name" { default = "orders-eks" }
variable "k8s_version"  { default = "1.30" }
variable "vpc_cidr"     { default = "10.20.0.0/16" }
variable "tags" {
  default = {
    Project = "EKS-Tech-Test"
  }
}
