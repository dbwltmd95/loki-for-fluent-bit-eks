data "aws_caller_identity" "my_account" {}

data "aws_eks_cluster" "eks" {
  name = module.eks.cluster_name
  depends_on = [module.eks]
}

data "http" "my-ip" {
  url             = "http://ifconfig.me"
  method          = "GET"
  request_headers = { "user-agent" : "curl/7.84.0" }
}

# kubernetes 설정
data "aws_eks_cluster_auth" "cluster_auth" {
  name = module.eks.cluster_name
}

# data "aws_iam_policy_document" "karpenter-controller-assume-role" {
#   statement {
#     effect = "Allow"
#     actions = ["sts:AssumeRoleWithWebIdentity"]
#
#     principals {
#       type        = "Federated"
#       identifiers = ["arn:aws:iam::${data.aws_caller_identity.my_account.account_id}:oidc-provider/${replace(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")}"]
#     }
#
#     condition {
#       test     = "StringEquals"
#       variable = "${replace(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")}:sub"
#       values   = ["system:serviceaccount:kube-system:karpenter"]
#     }
#   }
#
#   statement {
#     effect = "Allow"
#
#     principals {
#       type        = "Service"
#       identifiers = ["pods.eks.amazonaws.com"]
#     }
#
#     actions = [
#       "sts:AssumeRole",
#       "sts:TagSession"
#     ]
#   }
# }