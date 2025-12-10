# terraform\terraform.tfvars
###############################################################
# OKD SNO – Parámetros correctos y limpios
###############################################################

# Red NAT aislada para SNO
network_name = "okd-sno-net"
network_cidr = "10.66.0.0/24"

# Imágenes
coreos_image    = "/var/lib/libvirt/images/fedora-coreos-38.20230918.3.0-qemu.x86_64.qcow2"
almalinux_image = "/var/lib/libvirt/images/AlmaLinux-9-GenericCloud-9.5-20241120.x86_64.qcow2"

###############################################
# SSH KEYS
###############################################
ssh_keys = [
  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCdfUJjRAJuFcdO0J8CIOkjaKpqP6h9TqDRhZOJTac0199gFUvAJF9R/MAqwDLi2QI6OtYjz1CiCSVLtVQ2fTTIdwVibr+ZKDcbx/E7ivKUUbcmAOU8NP1gv3e3anoUd5k/0h0krP88CXosr41eTih4EcKhBAKbeZ11M0i9GZOux+/WweLtSQ3NU07sUkf1jDIoBungg77unmadqP3m9PUdkFP7tZ2lufcs3iq+vq8JaUBs/hZKNmWOXpnAyNxD9RlBJmvW2QgHmX53y3WC9bWUEUrwfDMB2wAqWPEDfj+5jsXQZcVE4pqD6T1cPaITnr9KFGnCCG1VQg31t1Jttg8z vhgalvez@gmail.com"
]

###############################################################
# Nodo Infra (DNS + NTP)
###############################################################
infra = {
  hostname = "infra.okd.local"
  ip       = "10.66.0.11"
  mac      = "52:54:00:aa:bb:77"
  cpus     = 2
  memory   = 2048
}

###############################################################
# Nodo SNO – Single Node OpenShift
###############################################################
sno = {
  hostname = "sno.okd.local"
  ip       = "10.66.0.10"
  mac      = "52:54:00:aa:bb:66"
  cpus     = 12
  memory   = 32768
}

###############################################################
# DNS + Gateway
###############################################################
dns1    = "10.66.0.11"  # Infra corre CoreDNS
dns2    = "8.8.8.8"
gateway = "10.66.0.1"

###############################################################
# Cluster Info
###############################################################
cluster_name   = "sno"
cluster_domain = "okd.local"

timezone = "UTC"
