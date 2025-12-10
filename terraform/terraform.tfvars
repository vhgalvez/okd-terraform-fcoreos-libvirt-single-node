# terraform\terraform.tfvars
###############################################################
# OKD SNO – Parámetros de despliegue
###############################################################

# Red NAT libvirt para el clúster
network_name = "okd-net"
network_cidr = "10.56.0.0/24"

# Imagen base de Fedora CoreOS (QCOW2)
coreos_image = "/var/lib/libvirt/images/fedora-coreos-38.20230918.3.0-qemu.x86_64.qcow2"

# Configuración del nodo único SNO (Single Node OpenShift)
sno = {
  hostname = "okd.okd.local"
  ip       = "10.56.0.10"
  mac      = "52:54:00:aa:bb:10"
  cpus     = 4
  memory   = 16384
}
