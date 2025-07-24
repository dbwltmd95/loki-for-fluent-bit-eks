# CloudWatch Policy #
data "aws_iam_policy_document" "pod-identity-role" {
  statement {
    effect = "Allow"

    principals { # 신뢰 개체
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"] # EKS Pod가 AWS 리소스에 대한 권한을 가지도록 IAM Role을 할당
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_role" "pod-identity-role" {
  name               = "yjs-fluentbit-pod-identity-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.pod-identity-role.json
}

resource "aws_iam_policy" "cloudwatch_policy" {
  name   = "yjs-cloudwatch-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents",
          "ec2:DescribeVolumes"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "pod-identity" {
  policy_arn = aws_iam_policy.cloudwatch_policy.arn
  role       = aws_iam_role.pod-identity-role.name
}

resource "aws_eks_pod_identity_association" "pod-identity" {
  cluster_name    = var.eks-cluster-name
  namespace       = "amazon-cloudwatch"
  service_account = "fluent-bit"
  role_arn        = aws_iam_role.pod-identity-role.arn
}