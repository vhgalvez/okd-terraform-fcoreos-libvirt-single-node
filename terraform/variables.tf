# terraform/variables.tf
###############################################################
# VARIABLES GLOBALES PARA OKD SNO – LIBVIRT
###############################################################

#############################
# Red Libvirt
#############################

variable "network_name" {
  type        = string
  description = "Nombre de la red NAT en libvirt que usará OKD SNO"
}

variable "network_cidr" {
  type        = string
  description = "CIDR de la red para el clúster (ej: 10.66.0.0/24)"
}

#############################
# Imágenes
#############################

variable "coreos_image" {
  type        = string
  description = "Ruta al QCOW2 de Fedora CoreOS"
}

variable "almalinux_image" {
  type        = string
  description = "Ruta al QCOW2 de AlmaLinux para el nodo infra"
}

#############################
# SSH Keys
#############################

variable "ssh_keys" {
  type        = list(string)
  description = "Llaves SSH autorizadas"
}

#############################
# Nodo Infra (DNS + NTP)
#############################

variable "infra" {
  description = "Nodo infra que provee DNS + NTP"
  type = object({
    hostname = string
    ip       = string
    mac      = string
    cpus     = number
    memory   = number
  })
}

#############################
# SNO – Single Node OpenShift
#############################

variable "sno" {
  description = "Nodo único del cluster OKD SNO"
  type = object({
    hostname = string
    ip       = string
    mac      = string
    cpus     = number
    memory   = number
  })
}

#############################
# DNS + Gateway
#############################

variable "dns1" {
  type        = string
  description = "Servidor DNS primario"
}

variable "dns2" {
  type        = string
  description = "Servidor DNS secundario"
}

variable "gateway" {
  type        = string
  description = "Puerta de enlace del cluster"
}

#############################
# Cluster Name / Domain
#############################

variable "cluster_name" {
  type        = string
  description = "Nombre del cluster (sno)"
}

variable "cluster_domain" {
  type        = string
  description = "Dominio del cluster (okd.local)"
}

#############################
# Timezone
#############################

variable "timezone" {
  type        = string
  description = "Zona horaria"
}


#############################################
# IP del nodo infra
#############################################
variable "infra_ip" {
  description = "IP del servidor infra (DNS forwarder)"
  type        = string
}
