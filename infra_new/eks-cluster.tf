resource "aws_security_group" "eks_sg" {
  name        = module.naming.cluster_sg
  description = "Cluster communication with gitlab worker nodes"
  vpc_id      = data.aws_vpc.current.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
  {
    Name = module.naming.cluster_sg,
    "tmna:terraform:script" = "eks-cluster.tf"
  }, module.naming.tags)
}

resource "aws_security_group_rule" "eks_ingress_allow" {
  cidr_blocks       = [var.gitlab_runners_cidr]
  description       = "Allow Gitlab to communicate with the cluster API server"
  from_port         = 443
  protocol          = "tcp"
  to_port           = 443
  security_group_id = aws_security_group.eks_sg.id
  type              = "ingress"
}

resource "aws_eks_cluster" "eks_one_kube" {
  name                      = module.naming.cluster_name
  role_arn                  = aws_iam_role.eks_cluster.arn
  enabled_cluster_log_types = ["api", "audit"]
  version                   = var.eks_kubernetes_version
  tags = merge({
    "tmna:terraform:script" = "eks-cluster.tf"
  }, module.naming.tags)

  vpc_config {
    security_group_ids = [aws_security_group.eks_sg.id]
    subnet_ids         = local.private_subnet_ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_one_kube_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks_one_kube_AmazonEKSServicePolicy,
  ]

  lifecycle {
    ignore_changes = [vpc_config.0.subnet_ids, version]
  }
}
