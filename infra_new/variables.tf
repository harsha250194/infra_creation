variable "access_key" {

}

variable "secret_key" {

}

variable "aws_region" {
  default = "us-west-2"
}

variable "key_name" {
  default = "terraform_key"
}

variable "vpc_id" {
  # use keyword "new" to create a new vpc otherwise it will use the given vpc_id
  default = "new"
}

variable "vpc_enable_dns_hostnames" {
  default = "true"
}

# Naming following rules: https://confluence.sdlc.toyota.com/pages/viewpage.action?spaceKey=TCPT&title=Naming+standards
#cluster_name + environment + reg/zone + resourcetype (eks for cluster) + serial no
#join("-", ["a","b","c"])
variable "resource_names" {
  type = map(string)
  default = {
    prefix = "onekube"
    environment = "dev"
    region = "usw2"
  }
}

variable "tag_names" {
  type = map(string)
  default = {
    "tmna:audit:createdby" = "" # will be filled by module
    "tmna:audit:createdon" = "" #will be filled by module
    "tmna:terraform:ver" = "0.12"
    "tmna:terraform:repo" = "gitlab/kubernetes-platform"
    "tmna:project:type" = "k8s-infra"
    "tmna:project:name" = "onekube"
    "tmna:env" = "sbx"
    "tmna:bu" = "CT"
    "tmna:team" = "21MM-CTP-Core"
  }
}

variable "eks_kubernetes_version" {
  default = "1.14"
}

variable "cidr_block" {
  description = "The CIDR block of the VPC created by this script"
  default     = "10.1.0.0/16"
}

variable "gitlab_runners_cidr" {
  description = "Security group cidr_block for the gitlab runners"
  default = "0.0.0.0/0" // TODO: this should be limited to the Gitlab IP range at some point, but for demo purposes we'll open it up large
}

variable "instance_types" {
  description = "Array of different types of instances"
  default = ["m4.large"]
}

variable "node_group_desired_size" {
  description = "Desired size of the EKS autoscaling worker node group"
  default = 3
}

variable "node_group_max_size" {
  description = "Max size of the EKS autoscaling worker node group"
  default = 10
}

variable "node_group_min_size" {
  description = "Min size of the EKS autoscaling worker node group"
  default = 1
}

variable "fargate_namespaces" {
  description = "Each namespace creates one profile, example kube-system"
  default = []
}

variable "subnet_count" {
  description = "Number of subnets to be created in VPC"
  default = 3
}

variable "subnet_newbits" {
  description = "8 will set 24 for /16 VPC, https://www.terraform.io/docs/configuration/functions/cidrsubnet.html"
  default = 8 # subnets with 256 IP addresses
}

variable "ddapikey" {
  default = ""
}