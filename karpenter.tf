# ###############################################
# # Auth - worker node
# ###############################################
# data "aws_iam_policy_document" "karpenter_workernode_assume_role" {
#   statement {
#     effect = "Allow"
#
#     principals {
#       type        = "Service"
#       identifiers = ["ec2.amazonaws.com"]
#     }
#
#     actions = [
#       "sts:AssumeRole",
#       "sts:TagSession"
#     ]
#   }
# }
#
# resource "aws_iam_role" "karpenter_workernode_role" {
#   name               = "${var.eks-cluster-name}-KarpenterWorkerNodeRole"
#   assume_role_policy = data.aws_iam_policy_document.karpenter_workernode_assume_role.json
# }
#
# resource "aws_iam_role_policy_attachment" "karpenter_workernode_AmazonEKSWorkerNodePolicy" { # EKS 클러스터에서 Worker Node로 작동하기 위해 필요한 기본 정책: 노드가 클러스터와 연결될 수 있도록 보장
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
#   role       = aws_iam_role.karpenter_workernode_role.name
# }
# resource "aws_iam_role_policy_attachment" "karpenter_workernode-AmazonEKS_CNI_Policy" { # EKS CNI(Container Network Interface) 관련 권한: Worker Node가 네트워크 인터페이스를 생성하고 관리할 수 있도록 허용
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
#   role       = aws_iam_role.karpenter_workernode_role.name
# }
# resource "aws_iam_role_policy_attachment" "karpenter_workernode_AmazonEC2ContainerRegistryReadOnly" { # Amazon ECR(AWS의 컨테이너 이미지 저장소)에서 이미지를 가져올 수 있는 권한
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
#   role       = aws_iam_role.karpenter_workernode_role.name
# }
# resource "aws_iam_role_policy_attachment" "karpenter_workernode_AmazonSSMManagedInstanceCore" { # AWS Systems Manager(SSM) 에이전트를 사용하여 Worker Node에 원격으로 접속하고 관리할 수 있도록 허용
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
#   role       = aws_iam_role.karpenter_workernode_role.name
# }
#
# ###############################################
# # Auth - controller
# ###############################################
# resource "aws_iam_role" "karpenter_controller_role" {
#   name               = "${var.eks-cluster-name}-KarpenterControllerRole"
#   assume_role_policy = data.aws_iam_policy_document.karpenter-controller-assume-role.json
# }
#
# resource "aws_iam_policy" "karpenter_controller_policy" {
#   name        = "${var.eks-cluster-name}-karpenter-controller-policy"
#   description = "IAM Policy for Karpenter Controller"
#   policy      = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "ssm:GetParameter",
#           "iam:GetInstanceProfile",
#           "iam:CreateInstanceProfile",
#           "iam:TagInstanceProfile",
#           "iam:AddRoleToInstanceProfile",
#           "iam:DeleteInstanceProfile",
#           "iam:RemoveRoleFromInstanceProfile",
#           "iam:PassRole",
#           "ec2:DescribeImages",
#           "ec2:RunInstances",
#           "ec2:DescribeSubnets",
#           "ec2:DescribeSecurityGroups",
#           "ec2:DescribeLaunchTemplates",
#           "ec2:DescribeInstances",
#           "ec2:DescribeInstanceTypes",
#           "ec2:DescribeInstanceTypeOfferings",
#           "ec2:DescribeSpotPriceHistory",
#           "ec2:CreateTags",
#           "ec2:CreateLaunchTemplate",
#           "ec2:CreateFleet",
#           "pricing:GetProducts"
#         ]
#         Effect   = "Allow"
#         Resource = "*"
#         Sid      = "Karpenter"
#       },
#       {
#         Action = [
#           "ec2:TerminateInstances",
#           "ec2:DeleteLaunchTemplate"
#         ]
#         Condition = { # 각 리소스는 and, 각 리소스 내부에선 or
#           StringEquals = {
#             "aws:ResourceTag/kubernetes.io/cluster/${var.eks-cluster-name}" = "owned"
#           }
#           StringLike = {
#             "aws:ResourceTag/karpenter.sh/nodepool" = "*"
#           }
#         }
#         Effect   = "Allow"
#         Resource = "*"
#         Sid      = "ConditionalEC2Termination"
#       },
#
#       {
#         Effect = "Allow"
#         Action = "eks:DescribeCluster"
#         Resource = "arn:aws:eks:ap-northeast-2:${data.aws_caller_identity.my_account.account_id}:cluster/${module.eks.cluster_name}"
#         Sid      = "EKSClusterEndpointLookup"
#       }
#     ]
#   })
# }
#
# resource "aws_iam_role_policy_attachment" "karpenter_controller_role_attachment" {
#   role       = aws_iam_role.karpenter_controller_role.name
#   policy_arn = aws_iam_policy.karpenter_controller_policy.arn
# }
#
#
# # Pod Identity
# resource "aws_eks_pod_identity_association" "karpenter_controller_association" {
#   cluster_name    = module.eks.cluster_name
#   namespace       = "kube-system"
#   service_account = "karpenter"
#   role_arn        = aws_iam_role.karpenter_controller_role.arn
# }
#
# # IAM 액세스 항목
# resource "aws_eks_access_entry" "karpneter_iam_access" {
#   cluster_name      = module.eks.cluster_name
#   principal_arn     = "arn:aws:iam::${data.aws_caller_identity.my_account.account_id}:role/${var.eks-cluster-name}-KarpenterWorkerNodeRole"
#   type              = "EC2_LINUX"
# }