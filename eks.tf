module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.37.1"

  cluster_name    = var.eks-cluster-name
  cluster_version = "1.33"

  # kms 암호화 비활성화
  create_kms_key                         = false
  cluster_encryption_config              = {} # etcd 암복호화

  # false로 설정 시, addons(CoreDNS, kube-proxy 등) 모듈이 자동으로 관리됨
  bootstrap_self_managed_addons = false

  cluster_addons = {
    coredns = {
      most_recent = true
      configuration_values = jsonencode({
        resources = {
          limits = {
            cpu    = "300m"
            memory = "350Mi"
          }
          requests = {
            cpu    = "300m"
            memory = "350Mi"
          }
        }
        autoScaling = {
          enabled     = true
          minReplicas = 2
          maxReplicas = 5
        }
      })
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      before_compute = true # 노드 그룹 생성 전에 먼저 설치 되어야 함
      most_recent    = true
    }
  }

  # Optional
  cluster_endpoint_public_access           = true # EKS API 서버가 인터넷에서 접근 가능하도록 설정
  enable_cluster_creator_admin_permissions = true # 클러스터 생성 IAM 사용자/역할에게 system:masters 권한 부여

  vpc_id                   = aws_vpc.yjs_vpc.id
  subnet_ids               = [aws_subnet.yjs_k8s_apne2_az1.id, aws_subnet.yjs_k8s_apne2_az3.id] # 노드 그룹이나 Fargate 등이 사용할 서브넷들
  control_plane_subnet_ids = [aws_subnet.yjs_k8s_apne2_az1.id, aws_subnet.yjs_k8s_apne2_az3.id] # 컨트롤 플레인 ENI가 위치할 서브넷들 (Private 권장)

  # EKS Managed Node Group(s)
  node_security_group_tags = {
    "karpenter.sh/discovery" = var.eks-cluster-name
  }

  eks_managed_node_group_defaults = {
    instance_types = ["t3.large"]
  }

  eks_managed_node_groups = {
    yjs-eks-mng = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.large"]
      capacity_type = "SPOT"

      min_size     = 2
      max_size     = 10
      desired_size = 2

      iam_role_additional_policies = {
        ssm-core = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }
    }
  }

  fargate_profiles = {
    core-dns = {
      name       = "yjs-coredns-fargate-profile"
      subnet_ids = [aws_subnet.yjs_k8s_apne2_az1.id, aws_subnet.yjs_k8s_apne2_az3.id]
      selectors = [
        {
          namespace = "kube-system",
          labels    = { k8s-app = "kube-dns" }
        }
      ]
    }
  }

  tags = {
    Terraform   = "true"
  }
}

# Fargate - CoreDNS 보안 설정 추가
resource "aws_vpc_security_group_ingress_rule" "allow_from_additional_sg_to_cluster_sg_tcp" {
  security_group_id = module.eks.cluster_primary_security_group_id  # 수신 대상 SG: 클러스터 보안 그룹
  referenced_security_group_id = module.eks.node_security_group_id  # 트래픽을 보내는 SG: 워커 노드의 보안 그룹
  from_port   = 53
  to_port     = 53
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_from_additional_sg_to_cluster_sg_udp" {
  security_group_id = module.eks.cluster_primary_security_group_id  # 수신 대상 SG: 클러스터 보안 그룹
  referenced_security_group_id = module.eks.node_security_group_id  # 트래픽을 보내는 SG: 워커 노드의 보안 그룹
  from_port   = 53
  to_port     = 53
  ip_protocol = "udp"
}



