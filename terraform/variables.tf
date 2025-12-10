##############################################################
# VARIABLES GLOBALES PARA OKD SNO – LIBVIRT
##############################################################

variable "almalinux_image" {
  type        = string
  description = "Ruta al QCOW2 de AlmaLinux para el nodo infra"
}

variable "dns1" {
  type        = string
  description = "DNS primario a usar en la red"
}

variable "dns2" {
  type        = string
  description = "DNS secundario"
}

variable "gateway" {
  type        = string
  description = "Gateway de la red NAT"
}

variable "cluster_name" {
  type        = string
}

variable "cluster_domain" {
  type        = string
}

variable "timezone" {
  type        = string
}

variable "ssh_keys" {
  type        = list(string)
}

variable "infra" {
  description = "Infra node (DNS + NTP)"
  type = object({
    hostname = string
    ip       = string
    mac      = string
    cpus     = number
    memory   = number
  })
}
