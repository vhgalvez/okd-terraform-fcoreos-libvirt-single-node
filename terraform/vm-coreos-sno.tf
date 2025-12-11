
# terraform\vm-coreos-sno.tf

###############################################
# DISK BASE + OVERLAY
###############################################

resource "libvirt_volume" "coreos_base" {
  name   = "fcos-base.qcow2"
  pool   = libvirt_pool.okd.name
  source = var.coreos_image
  format = "qcow2"
}

resource "libvirt_volume" "sno_disk" {
  name           = "okd-sno.qcow2"
  pool           = libvirt_pool.okd.name
  base_volume_id = libvirt_volume.coreos_base.id
  format         = "qcow2"
}

###############################################
# IGNITION — SNO REAL (bootstrap-in-place)
###############################################

resource "libvirt_ignition" "sno_ign" {
  name    = "sno.ign"
  pool    = libvirt_pool.okd.name
  content = file("${path.module}/../generated/bootstrap-in-place-for-live-iso.ign")
}

###############################################
# DOMAIN SNO
###############################################

resource "libvirt_domain" "sno" {
  name      = "okd-sno"
  vcpu      = var.sno.cpus
  memory    = var.sno.memory
  autostart = true

  disk {
    volume_id = libvirt_volume.sno_disk.id
  }

  network_interface {
    network_name   = libvirt_network.okd_net.name
    mac            = var.sno.mac
    addresses      = [var.sno.ip]
    hostname       = var.sno.hostname
    wait_for_lease = true
  }

  cpu {
    mode = "host-passthrough"
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

  video {
    type = "vga"
  }

  coreos_ignition = libvirt_ignition.sno_ign.id
  fw_cfg_name     = "opt/com.coreos/config"
}
