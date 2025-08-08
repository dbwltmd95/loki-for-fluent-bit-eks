# S3 버킷 생성
resource "aws_s3_bucket" "s3" {
  bucket = "yjs-loki-log"

  tags = {
    Name = "yjs-loki-log"
  }
}

# Trust Policy 정의 (Pod Identity 용)
data "aws_iam_policy_document" "assume_role_policy_doc" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole", "sts:TagSession"]
  }
}

# S3 권한 정책 정의
resource "aws_iam_policy" "s3_rw_policy" {
  name = "yjs-S3ReadWritePolicyForMyBucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::yjs-loki-log",
          "arn:aws:s3:::yjs-loki-log/*"
        ]
      }
    ]
  })
}

# IAM 역할 생성
resource "aws_iam_role" "s3_rw_role" {
  name               = "yjs-s3-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_doc.json
}

# IAM 역할과 정책 연결
resource "aws_iam_role_policy_attachment" "s3_rw" {
  policy_arn = aws_iam_policy.s3_rw_policy.arn
  role       = aws_iam_role.s3_rw_role.name
}

# EKS Pod Identity 연결
resource "aws_eks_pod_identity_association" "s3" {
  cluster_name    = module.eks.cluster_name
  namespace       = "monitoring"
  service_account = "loki-s3"
  role_arn        = aws_iam_role.s3_rw_role.arn
}
