
# terraform\network.tf
resource "libvirt_pool" "okd" {
  name = "okd"
  type = "dir"

  target {
    path = "/var/lib/libvirt/images/okd"
  }
}

resource "libvirt_network" "okd_net" {
  name      = var.network_name          # ej: "okd-sno-net"
  mode      = "nat"
  domain    = var.cluster_domain        # "okd.local"
  addresses = [var.network_cidr]        # "10.66.0.0/24"

  # 👉 Bridge con nombre fijo para este proyecto SNO
  bridge = "virbr-sno"

  # NAT para salida a Internet
  nat {
    enabled = true
  }

  # DHCP habilitado (para gateway/NAT de libvirt)
  dhcp {
    enabled = true
  }

  # DNS del propio bridge de libvirt
  dns {
    enabled = true

    # Forwarder principal → CoreDNS INFRA
    forwarders {
      address = var.dns1   # 10.66.0.11
    }

    # Forwarder secundario → DNS público
    forwarders {
      address = var.dns2   # 8.8.8.8
    }
  }
}
