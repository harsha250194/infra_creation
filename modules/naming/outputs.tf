#required to add the caller as tag
data "aws_caller_identity" "current" {}

output "tags" {
  value = merge(var.tag_names, {
    "tmna:audit:createdby" = split("/", data.aws_caller_identity.current.arn)[1]
    # "tmna:audit:createdon" = timestamp() # causing re-creation of all items
  })
}

output "annotations" {
  #value = zipmap(split(",", replace(join(",", keys(var.tag_names)), ":", "-")), values(var.tag_names))
  value = {for key, value in var.tag_names : replace(key, ":", "-") => value}
}

output "keys" {
  value = {key1: "tmna:terraform:script", "key2": "tmna-terraform-script"}
}

locals {
  merged_prefix = join("-", [var.resource_names.prefix, var.resource_names.environment, var.resource_names.region])
}

output "cluster_name" {
  value = join("-", [local.merged_prefix, "k8", "0"])
}

output "cluster_sg" {
  value = join("-", [local.merged_prefix, "sg", "0"])
}

output "cluster_node_sg" {
  value = join("-", [local.merged_prefix, "sg", "1"])
}

output "cluster_node_group_name" {
  value = join("-", [local.merged_prefix, "ng", "0"])
}

########## all roles ###################
output "cluster_role" {
  value = join("-", [local.merged_prefix, "rl", "0"])
}

output "cluster_node_role" {
  value = join("-", [local.merged_prefix, "rl", "1"])
}

output "cluster_autoscaler_role" {
  value = join("-", [local.merged_prefix, "rl", "2"])
}

output "cluster_dns_role" {
  # eks_one_kube_external_dns_role
  value = join("-", [local.merged_prefix, "rl", "3"])
}

output "letsencrypt_client_role" {
  # eks_one_kube_letsencrypt_client
  value = join("-", [local.merged_prefix, "rl", "4"])
}

output "post_process_role" {
  value = join("-", [local.merged_prefix, "rl", "5"])
}

output "fargate_role" {
  value = join("-", [local.merged_prefix, "rl", "6"])
}

output "aws_access_role" {
  value = join("-", [local.merged_prefix, "rl", "7"])
}

########## /all roles ###################

########## all role policies ###################
output "node_autoscaler_role_policy" {
  #old name was "eks_one_kube_node_autoscaler_policy"
  value = join("-", [local.merged_prefix, "rp", "0"])
}

output "cluster_autoscaler_role_policy" {
  #old name was "eks_one_kube_node_autoscaler_policy"
  value = join("-", [local.merged_prefix, "rp", "1"])
}

output "cluster_dns_role_policy" {
  # eks_one_kube_external_dns_policy
  value = join("-", [local.merged_prefix, "rp", "2"])
}

output "letsencrypt_dns_role_policy" {
  # eks_one_kube_letsencrypt_client
  value = join("-", [local.merged_prefix, "rp", "3"])
}

output "post_process_role_policy" {
  value = join("-", [local.merged_prefix, "rp", "4"])
}
########## /all role policies ###################
output "post_process_serviceaccount" {
  value = join("-", [local.merged_prefix, "sa", "0"])
}
########## service accounts ###################


########## /service accounts ###################

output "cluster_ec2_profile" {
  #old name was "one_kube_eks_iam_ins_prof"
  value = join("-", [local.merged_prefix, "pr", "0"])
}

output "cluster_alg_name_prefix" {
  # auto launch group name prefix
  value = join("-", [local.merged_prefix, "vm-"])
}

output "cluster_autoscaler_group" {
  value = join("-", [local.merged_prefix, "as", "0"])
}

output "network_vpc" {
  value = join("-", [local.merged_prefix, "vc", "0"])
}

output "network_subnets_prefix" {
  value = join("-", [local.merged_prefix, "sn"])
}

output "network_igateway" {
  value = join("-", [local.merged_prefix, "gw", "0"])
}

output "fargate_profile" {
  value = join("-", [local.merged_prefix, "fg", "0"])
}

#########test naming#############
output "cloud_test_sns_name" {
  value = join("-", [local.merged_prefix, "sn", "0"])
}
