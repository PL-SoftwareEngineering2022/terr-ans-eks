resource "aws_eks_cluster" "cali-eks-cluster" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.cali-eks-cluster-iam-role.arn
  #depends_on = [aws_cloudwatch_log_group.cali_cloudwatch_log_group] This argument is needed but since depends on cannot be done twice, the value for the depends on will be grouped with the other "depends on" values in the same resource
  enabled_cluster_log_types = ["api", "audit"]

  vpc_config {
    #subnet_ids = [aws_subnet.example1.id, aws_subnet.example2.id]
    subnet_ids = [var.aws_priv_subnet_id, var.aws_pub_subnet_id] #ID of VPC subnets required
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
