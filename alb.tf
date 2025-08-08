# 기존 워커 노드 IAM Role 가져오기
data "aws_iam_role" "worker_node_role" {
  name = module.eks.eks_managed_node_groups["yjs-eks-mng"].iam_role_name
}

# IAM 정책 정의
resource "aws_iam_policy" "alb_controller_policy" {
  name        = "${var.eks-cluster-name}-alb-controller-policy"
  path        = "/"
  description = "IAM policy for ALB"

  policy = file("${path.module}/policy/alb-controller.json")
}

# 기존 워커 노드 IAM Role에 정책만 붙이기
resource "aws_iam_role_policy_attachment" "alb_controller" {
  policy_arn = aws_iam_policy.alb_controller_policy.arn
  role       = data.aws_iam_role.worker_node_role.name
}

# 새로운 Assume Role 정책 정의
data "aws_iam_policy_document" "alb_controller_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

# IAM 역할 생성
resource "aws_iam_role" "alb_controller_role" {
  name               = "${var.eks-cluster-name}-alb-controller-role"
  assume_role_policy = data.aws_iam_policy_document.alb_controller_assume_role.json
}

# IAM 역할과 정책 연결
resource "aws_iam_role_policy_attachment" "yjs-alb" {
  policy_arn = aws_iam_policy.alb_controller_policy.arn
  role       = aws_iam_role.alb_controller_role.name
}

# EKS Pod Identity
resource "aws_eks_pod_identity_association" "alb_controller_pod_identity_association" {
  cluster_name    = module.eks.cluster_name
  namespace       = "kube-system"
  service_account = "alc"
  role_arn        = aws_iam_role.alb_controller_role.arn
}

# 추가 보안 그룹(개인 설정)
resource "aws_security_group" "alb_argocd_sg" {
  name        = "yjs-alb-argocd-sg"
  vpc_id      = aws_vpc.yjs_vpc.id
  tags = {
    Name = "yjs-alb-argocd-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_alb_argocd_ipv4" {
  security_group_id = aws_security_group.alb_argocd_sg.id
  cidr_ipv4         = "${data.http.my-ip.response_body}/32"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}
resource "aws_vpc_security_group_ingress_rule" "allow_alb_nginx_ipv4" {
  security_group_id = aws_security_group.alb_argocd_sg.id
  cidr_ipv4         = "${data.http.my-ip.response_body}/32"
  ip_protocol       = "tcp"
  from_port         = 8080
  to_port           = 8080
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_docker_ipv4" {
  security_group_id = aws_security_group.alb_argocd_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}