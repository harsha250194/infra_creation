resource "aws_eks_fargate_profile" "fargate_profile" {
  count = length(var.fargate_namespaces)
  cluster_name           = aws_eks_cluster.eks_one_kube.name
  fargate_profile_name   = module.naming.fargate_profile
  pod_execution_role_arn = aws_iam_role.pod_execution.0.arn
  subnet_ids             = local.private_subnet_ids

  selector {
    labels = {}
    namespace = var.fargate_namespaces[count.index]
  }
  tags = merge({
    "tmna:terraform:script" = "fargate-profile.tf"
  }, module.naming.tags)
}

resource "aws_iam_role" "pod_execution" {
  count = length(var.fargate_namespaces) > 0 ? 1 : 0
  name = module.naming.fargate_role

  assume_role_policy = jsonencode({
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
  tags = merge({
    "tmna:terraform:script" = "fargate-profile.tf"
  }, module.naming.tags)
}

resource "aws_iam_role_policy_attachment" "fargate_policy_attachment" {
  count = length(var.fargate_namespaces) > 0 ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.pod_execution.0.name
}