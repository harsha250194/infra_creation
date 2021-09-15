module "naming" {
  source = "../modules/naming"
  resource_names = var.resource_names
  tag_names = var.tag_names
}