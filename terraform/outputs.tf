# terraform/outputs.tf
###############################################################
# Terraform Outputs – OKD SNO + Infra Node
###############################################################

#############################
# SNO (Single Node OpenShift)
#############################

output "sno_ip" {
  description = "Dirección IP del nodo SNO"
  value       = var.sno.ip
}

output "sno_hostname" {
  description = "Hostname (FQDN) del nodo SNO"
  value       = var.sno.hostname
}

#############################
# Infra Node (DNS + NTP)
#############################

output "infra_ip" {
  description = "Dirección IP del nodo Infra (DNS + NTP)"
  value       = var.infra.ip
}

output "infra_hostname" {
  description = "Hostname (FQDN) del nodo Infra"
  value       = var.infra.hostname
}
