terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "harsha_personal"

    workspaces {
      prefix = "infra_creation"
    }
  }
}