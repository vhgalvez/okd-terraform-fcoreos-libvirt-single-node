# terraform/outputs.tf

###############################################################
# Terraform Outputs – OKD SNO
###############################################################

output "sno_ip" {
  description = "Dirección IP asignada al nodo Single Node OpenShift"
  value       = var.sno.ip
}

output "sno_hostname" {
  description = "Hostname completo (FQDN) del nodo SNO"
  value       = var.sno.hostname
}
