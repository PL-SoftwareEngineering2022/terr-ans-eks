terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.14.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region  = "us-west-1"
  profile = "default"
}


data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  #load_config_file       = false
}
