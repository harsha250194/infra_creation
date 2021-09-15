terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "connected-technologies"

    workspaces {
      prefix = "kubernetes-platform-"
    }
  }
}