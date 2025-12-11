
# terraform\network.tf
resource "libvirt_pool" "okd" {
  name = "okd"
  type = "dir"

  target {
    path = "/var/lib/libvirt/images/okd"
  }
}

resource "libvirt_network" "okd_net-sno" {
  name      = var.network_name        # ej: okd-sno-net
  mode      = "nat"
  bridge    = "virbr-sno"           # ej: virbr-sno
  addresses = [var.network_cidr]      # 10.66.0.0/24
  autostart = true

  # NO usamos domain= para no hacer libvirt autoritativo de okd.local

  dhcp {
    enabled = true
  }

  dns {
    enabled = true

    # Primer DNS → CoreDNS INFRA
    forwarders {
      address = var.dns1   # 10.66.0.11
    }

    # Segundo DNS → Google como fallback
    forwarders {
      address = var.dns2   # 8.8.8.8
    }
  }
}