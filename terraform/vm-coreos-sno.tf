
# terraform\vm-coreos-sno.tf

###############################################
# SNO – FEDORA COREOS
# Base image + overlay con tamaño definido
###############################################

# Imagen base (NO se toca tamaño)
resource "libvirt_volume" "coreos_base" {
  name   = "fcos-base.qcow2"
  pool   = libvirt_pool.okd.name
  source = var.coreos_image
  format = "qcow2"
}

# Disco real del nodo SNO (AQUÍ va el tamaño)
resource "libvirt_volume" "sno_disk" {
  name           = "okd-sno.qcow2"
  pool           = libvirt_pool.okd.name
  base_volume_id = libvirt_volume.coreos_base.id
  format         = "qcow2"

  size = var.sno.disk_size_gb * 1024 * 1024 * 1024
}

###############################################
# Ignition SNO (wrapper + merge correcto)
###############################################
resource "libvirt_ignition" "sno_ign" {
  name = "sno.ign"
  pool = libvirt_pool.okd.name

  content = templatefile(
    "${path.module}/file/sno-ignition-wrapper.json",
    {
      base_ign_b64 = base64encode(
        file("${path.module}/../generated/bootstrap-in-place-for-live-iso.ign")
      )
      dns1 = var.dns1
      dns2 = var.dns2
    }
  )
}

###############################################
# Dominio SNO
###############################################
resource "libvirt_domain" "sno" {
  name      = "okd-sno"
  vcpu      = var.sno.cpus
  memory    = var.sno.memory
  autostart = true

  cpu { mode = "host-passthrough" }

  disk {
    volume_id = libvirt_volume.sno_disk.id
  }

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

  network_interface {
    network_name   = libvirt_network.okd_net_sno.name
    mac            = var.sno.mac
    addresses      = [var.sno.ip]
    hostname       = var.sno.hostname
    wait_for_lease = true
  }

  coreos_ignition = libvirt_ignition.sno_ign.id
  fw_cfg_name     = "opt/com.coreos/config"
}