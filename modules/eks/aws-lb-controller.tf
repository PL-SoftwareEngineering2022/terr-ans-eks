locals {
 # aws_alb_ingress_controller_version      = var.aws_alb_ingress_controller_version
  aws_alb_ingress_class          = "alb"
  aws_vpc_id                     = var.vpc_id
  aws_region_name                = data.aws_region.current.name
  aws_iam_path_prefix            = var.aws_iam_path_prefix == "" ? null : var.aws_iam_path_prefix
  SA-Name                        = "aws-load-balancer-controller"
  lb_cluster_iam_role            = "aws-load-balancer-controller"
  lb-cluster-role-binding        = "aws-load-balancer-controller"
  ingress-controller-name        = "aws-load-balancer-controller"
}

data "aws_region" "current" { 
  name = var.region
}

data "aws_caller_identity" "current" {} # extracts AWS account ID

data "aws_iam_policy_document" "eks_oidc_assume_role" {
  count = var.k8s_cluster_type == "eks" ? 1 : 0
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.cali-eks-cluster.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values = [
        "system:serviceaccount:${var.namespace}:${local.SA-Name}" # <== namespace for service account
      ]
    }
    principals { # <== points to the account ID
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(aws_eks_cluster.cali-eks-cluster.identity[0].oidc[0].issuer, "https://", "")}"
      ]
      type = "Federated"
    }
  }
}

data "tls_certificate" "auth" {
  url = aws_eks_cluster.cali-eks-cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "oidc_ingress" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.auth.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.cali-eks-cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_role" "lb-controller-role" { # load balancer controller IAM role
  name        = "${var.eks_cluster_name}-aws-load-balancer-controller" # <== can be any name
  #name        = "${var.eks_cluster_name}-${local.serviceAccountName}" 
  description = "Permissions required by the Kubernetes AWS ALB Ingress controller to do it's job."
  path        = local.aws_iam_path_prefix

  #tags = var.aws_tags

  force_detach_policies = true

  assume_role_policy = data.aws_iam_policy_document.eks_oidc_assume_role[0].json
}


resource "aws_iam_policy" "lb-controller-policy" { # policy for load balance controller
  name        = "${var.aws_resource_name_prefix}-${var.eks_cluster_name}-alb-management"
  description = "Permissions that are required to manage AWS Application Load Balancers."
  path        = local.aws_iam_path_prefix
  policy      = file("./modules/eks/load-balancer-controller-policy.json") #or "${file("./modules/eks/load-balancer-controller-policy.json")}"
}

resource "aws_iam_role_policy_attachment" "this" {
  policy_arn = aws_iam_policy.lb-controller-policy.arn
  role       = aws_iam_role.lb-controller-role.name
}

resource "kubernetes_service_account" "k8s-SA" {  # attaches the IAM role to this service account
  automount_service_account_token = true
  metadata {
    name      = local.SA-Name
    namespace = var.namespace #alb-controller-namespace 
    annotations = {
      # This annotation is only used when running on EKS which can
      # use IAM roles for service accounts.
      "eks.amazonaws.com/role-arn" = aws_iam_role.lb-controller-role.arn
    }
    labels = {
      "app.kubernetes.io/name"       = "aws-load-balancer-controller"
      "app.kubernetes.io/component"  = "controller"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "kubernetes_cluster_role" "k8s-cluster-role" {
  metadata {
    name = local.lb_cluster_iam_role

    labels = {
      "app.kubernetes.io/name"       = local.lb_cluster_iam_role
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  rule {
    api_groups = [
      "",
      "extensions",
    ]

    resources = [
      "configmaps",
      "endpoints",
      "events",
      "ingresses",
      "ingresses/status",
      "services",
    ]

    verbs = [
      "create",
      "get",
      "list",
      "update",
      "watch",
      "patch",
    ]
  }

  rule {
    api_groups = [
      "",
      "extensions",
    ]

    resources = [
      "nodes",
      "pods",
      "secrets",
      "services",
      "namespaces",
    ]

    verbs = [
      "get",
      "list",
      "watch",
    ]
  }
}

resource "kubernetes_cluster_role_binding" "k8s-cluster-role-binding" {
  metadata {
    name = local.lb-cluster-role-binding

    labels = {
      "app.kubernetes.io/name"       = local.lb-cluster-role-binding
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.k8s-cluster-role.metadata[0].name
  }

  subject {
    api_group = ""
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.k8s-SA.metadata[0].name
    namespace = kubernetes_service_account.k8s-SA.metadata[0].namespace
  }
}

resource "helm_release" "aws-load-balancer-controller" {
  name       = local.ingress-controller-name

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = var.namespace #<==alb-controller namespace

  set {
    name  = "clusterName"
    value = var.eks_cluster_name
  }

  set {
    name  = "serviceAccount.name"
    value = local.SA-Name
  }

  set {
    name  = "serviceAccount.create"
    value = false # or "false". terraform will pick both eboulian values
  }

  set {
    name  = "image.repository"
    value = format("602401143452.dkr.ecr.%s.amazonaws.com/amazon/aws-load-balancer-controller",var.region)
  }

  # set {
  #   name  = "image.tag"
  #   value = "v2.4.1"
  # }

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }
depends_on = [
  aws_eks_fargate_profile.cali-fargate-profile
]

}
