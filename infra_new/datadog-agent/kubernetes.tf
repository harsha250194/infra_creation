data "aws_eks_cluster" "eks_one_kube" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "eks_one_kube" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks_one_kube.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_one_kube.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.eks_one_kube.token
  load_config_file       = false
  version                = "~> 1.13"
}
