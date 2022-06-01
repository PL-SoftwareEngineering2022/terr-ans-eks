module "network" {
  source             = "./modules/network"
  vpc_cidr           = var.vpc_cidr
  vpc-name           = var.vpc-name
  igw-name           = var.igw-name
  pub_cidr_block     = var.pub_cidr_block
  private_cidr_block = var.private_cidr_block
  eks_cluster_name   = var.eks_cluster_name
}

module "eks" {
  source                          = "./modules/eks"
  aws_priv_subnet_id              = module.network.private-subnet-ids
  aws_pub_subnet_id               = module.network.public-subnet-ids
  eks_cluster_name                = var.eks_cluster_name
  eks_cluster_iam_role_name       = var.eks_cluster_iam_role_name
  sg_name                         = var.sg_name
  vpc_id                          = module.network.vpc_id
  node_group_name                 = var.node_group_name
  node_role_name                  = var.node_role_name
  fargate_profile_name            = var.fargate_profile_name
  namespace                       = var.namespace
  fargate_pod_execution_role_name = var.fargate_pod_execution_role_name
}