provider "aws" {
  region  = "ap-northeast-2"
  profile = "cloudlab"
}

# kubernetes 설정
# 1) local에서 돌리는 세팅
# provider "kubernetes" {
#   config_path    = "~/.kube/config"
#   config_context = "yjs"
# }

# 2) ci/cd 같이 사용자 상관 없이 어디서든 돌릴 수 있는 세팅
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  # token                  = data.aws_eks_cluster_auth.cluster_auth.token
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["--region", "ap-northeast-2", "eks", "get-token", "--cluster-name", module.eks.cluster_name, "--output", "json"]
    command     = "aws"
  }
}
#
# provider "kubernetes" {
#   host                   = module.eks.cluster_endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority.0.data)
#   # token                  = data.aws_eks_cluster_auth.cluster_auth.token
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     args        = ["--region", "ap-northeast-2", "eks", "get-token", "--cluster-name", module.eks.cluster_name]
#     command     = "aws"
#     env = {
#       AWS_PROFILE = "cloudlab"
#     }
#   }
# }

output "auth" {
  value = module.eks.cluster_certificate_authority_data
}

output "cluster" {
  value = data.aws_eks_cluster.eks.certificate_authority.0.data
}