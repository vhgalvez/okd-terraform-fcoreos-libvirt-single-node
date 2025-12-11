#cloud-config
hostname: ${hostname}
manage_etc_hosts: true
timezone: ${timezone}

ssh_pwauth: false

users:
  - name: root
    ssh_authorized_keys:
      - ${ssh_keys}
  - name: core
    shell: /bin/bash
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    ssh_authorized_keys:
      - ${ssh_keys}

write_files:

  ###########################################################
  # NetworkManager: eth0 estático + DNS
  ###########################################################
  - path: /etc/NetworkManager/system-connections/eth0.nmconnection
    permissions: "0600"
    content: |
      [connection]
      id=eth0
      type=ethernet
      interface-name=eth0

      [ipv4]
      method=manual
      address1=${ip}/24,${gateway}
      dns=${dns1};${dns2}
      may-fail=false

      [ipv6]
      method=ignore

  ###########################################################
  # Zona DNS para sno.okd.local (CoreDNS)
  ###########################################################
  - path: /etc/coredns/db.sno.okd
    permissions: "0644"
    content: |
      $ORIGIN ${cluster_name}.${cluster_domain}.
      @   IN SOA infra.${cluster_name}.${cluster_domain}. admin.${cluster_name}.${cluster_domain}. (
            2025010101 7200 3600 1209600 3600 )
      @       IN NS infra.${cluster_name}.${cluster_domain}.
      infra   IN A ${infra_ip}

      api     IN A ${sno_ip}
      api-int IN A ${sno_ip}

      sno     IN A ${sno_ip}
      apps    IN A ${sno_ip}
      *.apps  IN A ${sno_ip}

  ###########################################################
  # Corefile de CoreDNS
  ###########################################################
  - path: /etc/coredns/Corefile
    permissions: "0644"
    content: |
      ${cluster_name}.${cluster_domain}.:53 {
        file /etc/coredns/db.sno.okd
        reload
      }
      .:53 {
        forward . 8.8.8.8 1.1.1.1
      }

  ###########################################################
  # Unit systemd para CoreDNS
  ###########################################################
  - path: /etc/systemd/system/coredns.service
    permissions: "0644"
    content: |
      [Unit]
      Description=CoreDNS DNS server
      After=network-online.target
      Wants=network-online.target

      [Service]
      ExecStart=/usr/local/bin/coredns -conf=/etc/coredns/Corefile
      Restart=always
      RestartSec=2

      [Install]
      WantedBy=multi-user.target

runcmd:
  # Recargar configuración de NetworkManager
  - nmcli connection reload
  - nmcli connection down eth0 || true
  - nmcli connection up eth0

  # Sincronización horaria y herramientas útiles
  - dnf install -y chrony firewalld bind-utils tar wget
  - systemctl enable --now chronyd

  # Abrir puertos DNS
  - systemctl enable --now firewalld
  - firewall-cmd --permanent --add-port=53/tcp
  - firewall-cmd --permanent --add-port=53/udp
  - firewall-cmd --reload

  # Crear directorio de CoreDNS
  - mkdir -p /etc/coredns

  # Descargar e instalar CoreDNS correctamente (tar.gz → binario)
  - cd /usr/local/bin
  - wget https://github.com/coredns/coredns/releases/download/v1.13.1/coredns_1.13.1_linux_amd64.tgz
  - tar -xzf coredns_1.13.1_linux_amd64.tgz
  - chmod +x /usr/local/bin/coredns

  # Activar servicio CoreDNS
  - systemctl daemon-reload
  - systemctl enable --now coredns

final_message: "Infra OKD DNS funcionando correctamente."