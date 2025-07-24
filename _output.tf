output "my_account" {
  value = data.aws_caller_identity.my_account.account_id
}

output "cluster_security_group" {
  value = module.eks.cluster_primary_security_group_id
}

output "addtional_security_group" {
  value = module.eks.cluster_security_group_id
}

