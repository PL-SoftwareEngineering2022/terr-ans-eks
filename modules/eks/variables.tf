variable "aws_priv_subnet_id" {
  type        = string
  description = "vpc private subnet id"
}
variable "aws_pub_subnet_id" {
  type        = string
  description = "vpc public subnet id"
}

variable "eks_cluster_name" {
  type        = string
}

variable "eks_cluster_iam_role_name" {
  type        = string
}

variable "sg_name" {
  type        = string
  description = "security group name"
  default     = "cali-eks-sg"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}