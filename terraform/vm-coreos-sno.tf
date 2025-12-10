
# terraform\vm-coreos-sno.tf

###############################################
# VM OKD SNO – Fedora CoreOS (Ignition)
###############################################

resource "libvirt_domain" "sno" {
  name      = "okd-sno"
  vcpu      = var.sno.cpus
  memory    = var.sno.memory
  autostart = true

  ###############################################
  # DISCO DE LA VM
  ###############################################
  disk {
    volume_id = libvirt_volume.sno_disk.id
  }

  ###############################################
  # RED – IP, MAC y hostname necesarios para OKD
  ###############################################
  network_interface {
    network_name   = libvirt_network.okd_net.name
    mac            = var.sno.mac
    addresses      = [var.sno.ip]
    hostname       = var.sno.hostname
    wait_for_lease = true
  }

  ###############################################
  # CPU PASSTHROUGH (requerido por FCOS/OKD)
  ###############################################
  cpu {
    mode = "host-passthrough"
  }

  ###############################################
  # CONSOLA SERIAL (Ignition la necesita)
  ###############################################
  console {
    type        = "pty"
    target_type = "serial"
    target_port = 0
  }

  ###############################################
  # VNC — Útil para debug
  ###############################################
  graphics {
    type           = "vnc"
    listen_type    = "address"
    listen_address = "127.0.0.1"
    autoport       = true
  }

  video {
    type = "vga"
  }

  ###############################################
  # IGNITION para Fedora CoreOS
  # Esto es CRÍTICO — sin esto NO ARRANCA OKD
  ###############################################
  coreos_ignition = libvirt_ignition.sno_ign.id
  fw_cfg_name     = "opt/com.coreos/config"
}
