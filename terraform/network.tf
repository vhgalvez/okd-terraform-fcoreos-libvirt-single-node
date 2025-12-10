# terraform/network.tf

###############################################################
# LIBVIRT STORAGE POOL
# Carpeta donde se guardan las imágenes QCOW2 del cluster
###############################################################
resource "libvirt_pool" "okd" {
  name   = "okd"
  type   = "dir"
  target = "/var/lib/libvirt/images/okd"
}


###############################################################
# LIBVIRT NAT NETWORK (sin DHCP)
# Sencilla, limpia y preparada para OKD SNO con IP estática
###############################################################
resource "libvirt_network" "okd_net" {
  name      = var.network_name
  mode      = "nat"
  domain    = "okd.local"
  addresses = [var.network_cidr]

  dhcp {
    enabled = false
  }
}
