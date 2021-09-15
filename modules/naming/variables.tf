variable "resource_names" {
  description = "Pass the same variable from root"
  type = map(string)
  default = {
    prefix = "tf"
    environment = "sbx"
    region = "use2"
  }
}

variable "tag_names" {
  description = "Pass the same variable from root"
  type = map(string)
}
