variable "access_key" {}

variable "secret_key" {}

variable "aws_region" {
  default = "us-east-2"
}

variable "cluster_name" {
  default = ""
}

variable "service_namespace" {}


variable "service_name" {}


variable "resource_names" {
}

variable "apikey" {
}

variable "environment" {
}

variable "tags" {
  default = {
    "tmna:terraform:ver"  = "0.12"
    "tmna:terraform:repo" = "gitlab.com/ctp1/connected-car-platform/kubernetes-platform/infra"
    "tmna:project:type" = "k8s-infra"
    "tmna:project:name" = "onekube"
    "tmna:env" = ""
    "tmna:bu" = "CT"
    "tmna:team" = "21MM-CTP-Core"
  }
}
