#cidr block for cali-vpc
variable "vpc_cidr" {
  type        = string
  description = "cidr_block for cali-vpc"
}

variable "vpc-name" {
  type        = string
  description = "vpc-name for the eks cluster"
}

variable "igw-name" {
  type        = string
  description = "internet gateway name for the eks cluster"
}

variable "pub_cidr_block" {
  type        = list(string)
  description = "vpc-name for the eks cluster"
  default     = ["10.0.1.0/24", "10.0.50.0/24"]
}

variable "private_cidr_block" {
  type        = list(string)
  description = "vpc-name for the eks cluster"
  default     = ["10.0.100.0/24", "10.0.150.0/24"]
}

# variable "aws_priv_subnet_id" {
#   type        = string
#   description = "vpc private subnet id"
# }
# variable "aws_pub_subnet_id" {
#   type        = string
#   description = "vpc public subnet id"
# }

variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "eks_cluster_iam_role_name" {
  type = string
}

variable "sg_name" {
  type        = string
  description = "security group name"
}

# variable "vpc_id" {
#   type        = string
#   description = "VPC ID"
# }

variable "node_group_name" {
  type        = string
  description = "name of node group"
}

variable "node_role_name" {
  type        = string
  description = "node role name"
}

variable "fargate_profile_name" {
  type        = string
  description = "name of fargate profile"
}

variable "namespace" {
  type        = string
  description = "name of the namespace in the fargate profile selector"
}

variable "fargate_pod_execution_role_name" {
  type        = string
  description = "name of the fargate pod execution role"
}

