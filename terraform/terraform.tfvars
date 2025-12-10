# terraform\terraform.tfvars

###############################################################
# OKD SNO – Parámetros correctos y limpios
###############################################################

# Red NAT aislada para SNO
network_name = "okd-sno-net"
network_cidr = "10.66.0.0/24"

# Imagen Fedora CoreOS
coreos_image = "/var/lib/libvirt/images/fedora-coreos-38.20230918.3.0-qemu.x86_64.qcow2"

# Nodo único SNO
sno = {
  hostname = "sno.okd.local"   # dominio consistente
  ip       = "10.66.0.10"
  mac      = "52:54:00:aa:bb:66"
  cpus     = 12
  memory   = 32768
}

###############################################################
# DNS CONFIG – PARA SNO 
###############################################################

dns1    = "10.66.0.10"   # El propio nodo actuará como DNS interno
dns2    = "8.8.8.8"
gateway = "10.66.0.1"    # La pasarela de la red libvirt NAT

###############################################################
# CLUSTER NAME / DOMAIN – DEBE COINCIDIR CON EL HOSTNAME
###############################################################

cluster_name   = "sno"
cluster_domain = "okd.local"

timezone = "UTC"

infra_ip = "10.66.0.10"   # Solo para compatibilidad; no se usa en SNO
