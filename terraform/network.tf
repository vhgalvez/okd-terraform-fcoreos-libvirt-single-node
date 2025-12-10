# terraform/network.tf

resource "libvirt_pool" "okd" {
  name = "okd"
  type = "dir"

  target {
    path = "/var/lib/libvirt/images/okd"
  }
}

resource "libvirt_network" "okd_net" {
  name      = var.network_name
  mode      = "nat"
  domain    = "okd.local"
  addresses = [var.network_cidr]

  dhcp {
    enabled = false
  }
}
