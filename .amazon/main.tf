terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}
variable "agones_version" {
  default = ""
}

variable "cluster_name" {
  default = ""
}

variable "region" {
  default = ""
}

variable "node_count" {
  default = "4"
}

provider "aws" {
  region = var.region
}

variable "machine_type" { 
    default = "t2.large" 
}

variable "log_level" {
  default = "info"
}

variable "feature_gates" {
  default = ""
}

module "eks_cluster" {
  source = "git::https://github.com/googleforgames/agones.git//install/terraform/modules/eks/?ref=main"

  machine_type = var.machine_type
  cluster_name = var.cluster_name
  node_count   = var.node_count
  region       = var.region
}

data "aws_eks_cluster_auth" "default" {
  name = var.cluster_name
}

# module "helm_agones" {

#   source = "git::https://github.com/googleforgames/agones.git//install/terraform/modules/helm3/?ref=main"

#   udp_expose             = "true"
#   agones_version         = var.agones_version
# #   gameserver_namespaces  = ["default", "xonotic"]
#   feature_gates          = var.feature_gates
#   host                   = module.eks_cluster.host
#   token                  = data.aws_eks_cluster_auth.default.token
#   cluster_ca_certificate = module.eks_cluster.cluster_ca_certificate
# }

output "host" {
  value = "${module.eks_cluster.host}"
}
output "cluster_ca_certificate" {
  value = "${module.eks_cluster.cluster_ca_certificate}"
}