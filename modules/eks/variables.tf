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

variable "region" {
  description = "Name of region"
}

# variable "serviceAccountName" {
#   description = "name of the service account for the ALB controller"
# }

variable "k8s_cluster_type" {
  description = "Can be set to `vanilla` or `eks`. If set to `eks`, the Kubernetes cluster will be assumed to be run on EKS which will make sure that the AWS IAM Service integration works as supposed to."
  type        = string
  default     = "eks"
}

variable "aws_iam_path_prefix" {
  description = "Prefix to be used for all AWS IAM objects."
  type        = string
  default     = ""
}

variable "aws_resource_name_prefix" {
  description = "A string to prefix any AWS resources created. This does not apply to K8s resources"
  type        = string
  default     = "k8s-"
}