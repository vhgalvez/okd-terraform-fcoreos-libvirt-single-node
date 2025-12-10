
# terraform\network.tf
resource "libvirt_pool" "okd" {
  name = "okd"
  type = "dir"

  target {
    path = "/var/lib/libvirt/images/okd"
  }
}

resource "libvirt_network" "okd_net" {
  name      = var.network_name        # "okd-sno-net"
  mode      = "nat"                   # NAT auto gestionado
  domain    = var.cluster_domain      # "okd.local"
  addresses = [var.network_cidr]      # "10.66.0.0/24"

  # Importante: bridge para esta red SNO
  bridge = "virbr-sno"

  # DHCP solo para gateway interno de libvirt
  dhcp {
    enabled = true
  }

  # Bloque DNS soportado por Terraform/libvirt
  dns {
    enabled = true

    forwarders {
      address = var.dns1   # CoreDNS INFRA 10.66.0.11
    }

    forwarders {
      address = var.dns2   # Google DNS 8.8.8.8
    }
  }
}

