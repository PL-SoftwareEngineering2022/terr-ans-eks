variable "aws_priv_subnet_id" {
  description = "vpc private subnet id"
}
variable "aws_pub_subnet_id" {
  description = "vpc public subnet id"
}

variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "eks_cluster_iam_role_name" {
  type        = string
  description = "name of the EKS cluster IAM role"
}

variable "sg_name" {
  type        = string
  description = "security group name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "node_group_name" {
  type        = string
  description = "name of node group"
}

variable "node_role_name" {
  type = string
  description = "node role name"
}

variable "fargate_profile_name" {
  type = string
  description = "name of fargate profile"
}

variable "namespace" {
  type = string
  description = "name of the namespace in the fargate profile selector"
}

variable "fargate_pod_execution_role_name" {
  type = string
  description = "name of the fargate pod execution role"
}
