# terraform/vm-infra.tf
###############################################
# DISCO DEL NODO INFRA (AlmaLinux)
###############################################
resource "libvirt_volume" "infra_disk" {
  name   = "okd-infra.qcow2"
  pool   = libvirt_pool.okd.name
  source = var.almalinux_image
  format = "qcow2"
  size   = var.infra.disk_size_gb * 1024 * 1024 * 1024

}

data "template_file" "infra_cloud_init" {
  template = file("${path.module}/file/cloud-init-infra.tpl")

  vars = {
    hostname       = var.infra.hostname
    short_hostname = split(".", var.infra.hostname)[0]
    ip             = var.infra.ip
    infra_ip       = var.infra.ip
    sno_ip         = var.sno.ip
    gateway        = var.gateway
    dns1           = var.dns1
    dns2           = var.dns2
    cluster_name   = var.cluster_name
    cluster_domain = var.cluster_domain
    timezone       = var.timezone
    ssh_keys       = join("\n", var.ssh_keys)
  }
}

resource "libvirt_cloudinit_disk" "infra_init" {
  name      = "infra-cloudinit.iso"
  user_data = data.template_file.infra_cloud_init.rendered

  meta_data = yamlencode({
    "instance-id"    = "okd-infra"
    "local-hostname" = var.infra.hostname
  })
}

resource "libvirt_domain" "infra" {
  name      = "okd-infra"
  vcpu      = var.infra.cpus
  memory    = var.infra.memory
  autostart = true

  cpu { mode = "host-passthrough" }

  arch    = "x86_64"
  machine = "pc"

  console {
    type        = "pty"
    target_type = "serial"
    target_port = 0
  }

  graphics {
    type           = "vnc"
    listen_type    = "address"
    listen_address = "127.0.0.1"
    autoport       = true
  }

  video { type = "vga" }

  disk {
    volume_id = libvirt_volume.infra_disk.id
  }

  cloudinit = libvirt_cloudinit_disk.infra_init.id

  network_interface {
    network_name = libvirt_network.okd_net_sno.name
    mac          = var.infra.mac
    addresses    = [var.infra.ip]
    hostname     = var.infra.hostname
  }
}
