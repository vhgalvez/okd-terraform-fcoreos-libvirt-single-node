
# terraform\network.tf
resource "libvirt_pool" "okd" {
  name = "okd"
  type = "dir"

  target {
    path = "/var/lib/libvirt/images/okd"
  }
}

resource "libvirt_network" "okd_net_sno" {
  name      = var.network_name
  mode      = "nat"
  bridge    = "virbr-sno"
  addresses = [var.network_cidr]
  autostart = true

  dhcp {
    enabled = true
  }

  dns {
    enabled = true

    forwarders {
      address = var.dns1   # CoreDNS infra
    }
    forwarders {
      address = var.dns2   # Google fallback
    }
  }
}