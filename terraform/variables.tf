##############################################################
# VARIABLES GLOBALES PARA OKD SNO – LIBVIRT
##############################################################

#############################
# Red Libvirt
#############################

variable "network_name" {
  type        = string
  description = "Nombre de la red NAT en libvirt que usará OKD"
}

variable "network_cidr" {
  type        = string
  description = "CIDR de la red para el clúster (ej: 10.56.0.0/24)"
}


#############################
# Imagen Fedora CoreOS
#############################

variable "coreos_image" {
  type        = string
  description = "Ruta al archivo QCOW2 de Fedora CoreOS en el host libvirt"
}


#############################
# Single Node Configuration
#############################

variable "sno" {
  description = "Parámetros del nodo único de OKD (Single Node OpenShift)"
  
  type = object({
    hostname = string        # FQDN del nodo SNO (ej: okd.okd.local)
    ip       = string        # IP estática del nodo
    mac      = string        # MAC del nodo para libvirt
    cpus     = number        # Núcleos asignados
    memory   = number        # Memoria RAM en MB
  })
}
