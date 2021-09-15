resource "aws_eks_node_group" "onekube_node_group" {
  cluster_name    = aws_eks_cluster.eks_one_kube.name
  node_group_name = module.naming.cluster_node_group_name
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = local.private_subnet_ids

  instance_types = var.instance_types
  scaling_config {
    desired_size = var.node_group_desired_size
    min_size     = var.node_group_min_size
    max_size     = var.node_group_max_size
  }
  tags = merge({
    "tmna:terraform:script" = "worker-nodes.tf"
  }, module.naming.tags)

  lifecycle {
    ignore_changes = [subnet_ids, instance_types]
  }
}

//locals {
//  asg_name = data.aws_autoscaling_groups.eks_nodegroup_asgs.names[0]
//}
//
//data "aws_autoscaling_groups" "eks_nodegroup_asgs" {
//  filter {
//    name   = "key"
//    values = ["k8s.io/cluster-autoscaler/${aws_eks_cluster.eks_one_kube.name}"]
//  }
//
//  filter {
//    name   = "value"
//    values = ["owned"]
//  }
//
//}
//
//resource "null_resource" "update_asg_tags" {
//  provisioner "local-exec" {
//    command = "aws autoscaling create-or-update-tags --tags ResourceId=${local.asg_name}},ResourceType=auto-scaling-group,Key=tmna:team,Value=21mm,PropagateAtLaunch=true"
//    environment = {
//      AWS_ACCESS_KEY_ID = var.access_key
//      AWS_SECRET_ACCESS_KEY = var.secret_key
//      AWS_DEFAULT_REGION = var.aws_region
//    }
//  }
//  depends_on = aws_eks_node_group.onekube_node_group
//}
