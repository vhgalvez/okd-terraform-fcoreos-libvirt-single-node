# terraform/main.tf

###############################################################
# Terraform Settings
###############################################################
terraform {
  required_version = ">= 1.14.1, < 2.0.0"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.8.3"
    }
  }
}

###############################################################
# Libvirt Provider
###############################################################
provider "libvirt" {
  uri = "qemu:///system"
}
