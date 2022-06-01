resource "aws_eks_cluster" "cali-eks-cluster" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.cali-eks-cluster-iam-role.arn
  #depends_on = [aws_cloudwatch_log_group.cali_cloudwatch_log_group] This argument is needed but since depends on cannot be done twice, the value for the depends on will be grouped with the other "depends on" values in the same resource
  enabled_cluster_log_types = ["api", "audit"]

  vpc_config {
    #subnet_ids = [aws_subnet.cali-pub-subnet.id, aws_subnet.cali-priv-subnet.id]
    subnet_ids = concat(var.aws_priv_subnet_id, var.aws_pub_subnet_id) #ID of VPC subnets required
    security_group_ids = [aws_security_group.cali-eks-sg.id]
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.cali-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cali-AmazonEKSVPCResourceController,
    aws_cloudwatch_log_group.cali_cloudwatch_log_group,
  ]
}

resource "aws_iam_role" "cali-eks-cluster-iam-role" {
  name = var.eks_cluster_iam_role_name

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "cali-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cali-eks-cluster-iam-role.name
}

# Optionally, enable Security Groups for Pods
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html
resource "aws_iam_role_policy_attachment" "cali-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cali-eks-cluster-iam-role.name
}

/*output "endpoint" {
  value = aws_eks_cluster.example.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.example.certificate_authority[0].data
}*/

# security group for eks cluster
resource "aws_security_group" "cali-eks-sg" {
  name        = var.sg_name
  description = "Allow http/s traffic"
  vpc_id      =  var.vpc_id #aws_vpc.main.id but since it is another folder, we need to reference it as a variable in this folder

  ingress {
    description      = "http/s traffic"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"] #whitelist IPs/cidr block to be used to restrict ingress traffic
    #ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "cali-eks-sg"
  }
}

#cloudwatch IAM policy
resource "aws_iam_policy" "AmazonEKSClusterCloudWatchMetricsPolicy" {
  name   = "AmazonEKSClusterCloudWatchMetricsPolicy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "cloudwatch:PutMetricData"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "AmazonEKSCloudWatchMetricsPolicy" {
policy_arn = aws_iam_policy.AmazonEKSClusterCloudWatchMetricsPolicy.arn
role       = aws_iam_role.cali-eks-cluster-iam-role.name
}

resource "aws_cloudwatch_log_group" "cali_cloudwatch_log_group" {
  # The log group name format is /aws/eks/<cluster-name>/cluster
  # Reference: https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html
name =  "/aws/eks/${var.eks_cluster_name}/cluster" #"/aws/eks/${var.eks_cluster_name}-${var.environment}/cluster"
retention_in_days = 1 # var.retention_in_days

/*tags = {
   Name   = "${var.eks_cluster_name}-${var.environment}-eks-cloudwatch-log-group" #"${var.eks_cluster_name}-${var.environment}-eks-cloudwatch-log-group"
 }*/

}

# node group
resource "aws_eks_node_group" "cali-node-group" {
  cluster_name    = aws_eks_cluster.cali-eks-cluster.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.cali-node-role.arn
  subnet_ids      = concat(var.aws_priv_subnet_id) # or var.aws_priv_subnet_id
  ami_type        = "AL2_x86_64"
  instance_types  = ["t2.micro"]

  scaling_config {
    desired_size = 2
    max_size     = 10
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.cali-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.cali-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.cali-AmazonEC2ContainerRegistryReadOnly,
  ]
}

#node IAM role and Attachments
resource "aws_iam_role" "cali-node-role" {
  name = var.node_role_name

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "cali-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.cali-node-role.name
}

resource "aws_iam_role_policy_attachment" "cali-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.cali-node-role.name
}

resource "aws_iam_role_policy_attachment" "cali-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.cali-node-role.name
}

# Fargate Profile
resource "aws_eks_fargate_profile" "cali-fargate-profile" {
  cluster_name           = aws_eks_cluster.cali-eks-cluster.name
  fargate_profile_name   = var.fargate_profile_name
  pod_execution_role_arn = aws_iam_role.cali_fargate_pod_execution_role.arn
  subnet_ids             = var.aws_priv_subnet_id

  selector { # can have up to 5 selectors per fargate profile
    namespace = var.namespace # anything created in this namespace will use the fargate profile
  }
}

#fargate profile pod execution role
resource "aws_iam_role" "cali_fargate_pod_execution_role" {
  name = var.fargate_pod_execution_role_name

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "cali-AmazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.cali_fargate_pod_execution_role.name
}

#fargate namespace
resource "kubernetes_namespace" "fargate_selector_namespace" {
  metadata {
    name = var.namespace
  }
}

