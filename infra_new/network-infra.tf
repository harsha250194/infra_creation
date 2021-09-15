data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "current" {
  id = var.vpc_id == "new" ? aws_vpc.one_kube_new_vpc[0].id : var.vpc_id
  depends_on = [aws_vpc.one_kube_new_vpc]
}

data "aws_subnet_ids" "public" {
  vpc_id = var.vpc_id == "new" ? aws_vpc.one_kube_new_vpc[0].id : var.vpc_id
  tags = {
    "tmna:subnet:type" = "public"
  }
  depends_on = [aws_vpc.one_kube_new_vpc, aws_subnet.eks_one_kube_new_public_subnets]
}

data "aws_subnet_ids" "private" {
  vpc_id = var.vpc_id == "new" ? aws_vpc.one_kube_new_vpc[0].id : var.vpc_id
  tags = {
    "tmna:subnet:type" = "private"
  }
  depends_on = [aws_vpc.one_kube_new_vpc, aws_subnet.eks_one_kube_new_private_subnets]
}

locals {
//  public_subnet_ids = slice(sort(data.aws_subnet_ids.public.ids), 0, var.subnet_count)
//  private_subnet_ids = slice(sort(data.aws_subnet_ids.private.ids), 0, var.subnet_count)
  public_subnet_ids = tolist(sort(data.aws_subnet_ids.public.ids))
  private_subnet_ids = tolist(sort(data.aws_subnet_ids.private.ids))
}

resource "aws_vpc" "one_kube_new_vpc" {
  count = var.vpc_id == "new" ? 1 : 0 #only if it is new, the resource is created

  cidr_block = var.cidr_block
  enable_dns_hostnames = var.vpc_enable_dns_hostnames

  tags = merge({
    "Name"                                                = module.naming.network_vpc
    "kubernetes.io/cluster/${module.naming.cluster_name}" = "shared"
    "tmna:terraform:script"                               = "network-infra.tf"
    },
  module.naming.tags)
}

#fargate requires private subnets
resource "aws_subnet" "eks_one_kube_new_private_subnets" {
  count = var.vpc_id == "new" ? var.subnet_count : 0

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(var.cidr_block, var.subnet_newbits, count.index + var.subnet_count) # 10.1.0.0/16 -> 10.1.2.0/24 & 10.1.3.0/24
  vpc_id            = data.aws_vpc.current.id
  tags = merge({
    "Name"                                                = join("-", [module.naming.network_subnets_prefix, tostring(count.index + var.subnet_count)])
    "kubernetes.io/cluster/${module.naming.cluster_name}" = "shared"
    "tmna:terraform:script"                               = "network-infra.tf"
    "tmna:subnet:type"                                    = "private"
  },
  module.naming.tags)

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "aws_subnet" "eks_one_kube_new_public_subnets" {
  count = var.vpc_id == "new" ? var.subnet_count : 0

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(var.cidr_block, var.subnet_newbits, count.index) # 10.1.0.0/16 -> 10.1.0.0/24 & 10.1.1.0/24
  vpc_id            = data.aws_vpc.current.id
  map_public_ip_on_launch = true
  tags = merge({
    "Name"                                                = join("-", [module.naming.network_subnets_prefix, tostring(count.index)])
    "kubernetes.io/cluster/${module.naming.cluster_name}" = "shared"
    "tmna:terraform:script"                               = "network-infra.tf"
    "tmna:subnet:type"                                    = "public"
    },
  module.naming.tags)

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "aws_internet_gateway" "eks_one_kube" {
  count = var.vpc_id == "new" ? 1 : 0

  vpc_id = data.aws_vpc.current.id
  tags = merge({
    Name                    = module.naming.network_igateway
    "tmna:terraform:script" = "network-infra.tf"
    },
  module.naming.tags)
}

resource "aws_route_table" "eks_one_kube_pub" {
  count = var.vpc_id == "new" ? 1 : 0

  vpc_id = data.aws_vpc.current.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_one_kube[0].id
  }

  tags = merge({
    "Name" = "${var.resource_names.prefix}-${var.resource_names.environment}-${var.resource_names.region}-public-rt"
    "tmna:terraform:script" = "network-infra.tf"
  }, module.naming.tags)

  lifecycle {
    ignore_changes = [route, tags]
  }
}

resource "aws_route_table_association" "eks_one_kube_pub" {
  count = var.vpc_id == "new" ? var.subnet_count : 0

  subnet_id      = local.public_subnet_ids[count.index]
  route_table_id = aws_route_table.eks_one_kube_pub[0].id

  lifecycle {
    ignore_changes = [subnet_id]
  }
}

resource "aws_eip" "nat" {
  count = var.vpc_id == "new" ? 1 : 0

  vpc = true

  tags = merge({
    "Name" = format(
        "eip-natgw-%s", count.index),
    "tmna:terraform:script" = "network-infra.tf"
    }, module.naming.tags)
}

resource "aws_nat_gateway" "natgw" {
  count = var.vpc_id == "new" ? 1 : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id = aws_subnet.eks_one_kube_new_public_subnets[count.index].id

  tags = merge(
    {
      "Name" = format(
        "natgw-%s", aws_subnet.eks_one_kube_new_public_subnets[count.index].id),
      "tmna:terraform:script" = "network-infra.tf"
    }, module.naming.tags)

  depends_on = [aws_internet_gateway.eks_one_kube]
}

resource "aws_route_table" "eks_one_kube_priv" {
  count = var.vpc_id == "new" ? 1 : 0

  vpc_id = data.aws_vpc.current.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgw[0].id
  }

  tags = merge({
    "Name" = "${var.resource_names.prefix}-${var.resource_names.environment}-${var.resource_names.region}-private-rt"
    "tmna:terraform:script" = "network-infra.tf"
  }, module.naming.tags)

  lifecycle {
    ignore_changes = [route, tags]
  }
}

resource "aws_route_table_association" "eks_one_kube_priv" {
  count = var.subnet_count

  subnet_id      = local.private_subnet_ids[count.index]
  route_table_id = aws_route_table.eks_one_kube_priv[0].id

  lifecycle {
    ignore_changes = [subnet_id]
  }
}
