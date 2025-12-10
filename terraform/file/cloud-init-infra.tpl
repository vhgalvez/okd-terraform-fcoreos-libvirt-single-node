#cloud-config
hostname: ${hostname}
manage_etc_hosts: true
timezone: ${timezone}

ssh_pwauth: false
disable_root: false

users:
  - default

  # Usuario core
  - name: core
    gecos: "Core User"
    groups: [wheel]
    shell: /bin/bash
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    lock_passwd: false
    ssh_authorized_keys:
      - ${ssh_keys}

  # Usuario root
  - name: root
    ssh_authorized_keys:
      - ${ssh_keys}

package_update: true
package_upgrade: true

packages:
  - chrony
  - firewalld
  - bind-utils
  - curl
  - tar

write_files:

  ###########################################################
  # CoreDNS - Zona DNS para SNO
  ###########################################################
  - path: /etc/coredns/db.okd
    permissions: "0644"
    content: |
      $ORIGIN ${cluster_name}.${cluster_domain}.
      @ IN SOA infra.${cluster_name}.${cluster_domain}. admin.${cluster_name}.${cluster_domain}. (
          2025010101 7200 3600 1209600 3600 )

      @       IN NS infra.${cluster_name}.${cluster_domain}.
      infra   IN A ${ip}

      # Registros necesarios para SNO
      api     IN A ${sno_ip}
      api-int IN A ${sno_ip}
      ${cluster_name} IN A ${sno_ip}

  ###########################################################
  # CoreDNS — Corefile escuchando en puerto 53
  ###########################################################
  - path: /etc/coredns/Corefile
    permissions: "0644"
    content: |
      ${cluster_name}.${cluster_domain}.:53 {
        file /etc/coredns/db.okd
      }

      .:53 {
        forward . 8.8.8.8 1.1.1.1
      }

  ###########################################################
  # systemd unit - CoreDNS
  ###########################################################
  - path: /etc/systemd/system/coredns.service
    permissions: "0644"
    content: |
      [Unit]
      Description=CoreDNS DNS server
      After=network-online.target
      Wants=network-online.target

      [Service]
      ExecStart=/usr/local/bin/coredns -conf=/etc/coredns/Corefile -dns.port=53
      Restart=always
      RestartSec=2
      LimitNOFILE=1048576

      [Install]
      WantedBy=multi-user.target

runcmd:

  ###########################################################
  # Descargar binario CoreDNS — CORREGIDO
  ###########################################################
  - mkdir -p /etc/coredns
  - cd /tmp
  - curl -LO https://github.com/coredns/coredns/releases/download/v1.13.1/coredns_1.13.1_linux_amd64.tgz
  - tar -xzf coredns_1.13.1_linux_amd64.tgz
  - mv coredns /usr/local/bin/coredns
  - chmod +x /usr/local/bin/coredns

  ###########################################################
  # NTP local
  ###########################################################
  - systemctl enable --now chronyd
  - sed -i 's/^pool.*/server 10.66.0.1 iburst/' /etc/chrony.conf
  - echo "allow 10.66.0.0/24" >> /etc/chrony.conf
  - systemctl restart chronyd

  ###########################################################
  # resolv.conf del infra → Infra + 8.8.8.8
  ###########################################################
  - rm -f /etc/resolv.conf
  - printf "nameserver ${ip}\nnameserver 8.8.8.8\nsearch ${cluster_name}.${cluster_domain}\n" > /etc/resolv.conf

  ###########################################################
  # Firewall y servicios
  ###########################################################
  - systemctl enable --now firewalld
  - firewall-cmd --permanent --add-port=53/tcp
  - firewall-cmd --permanent --add-port=53/udp
  - firewall-cmd --reload

  ###########################################################
  # Habilitar CoreDNS
  ###########################################################
  - systemctl daemon-reload
  - systemctl enable --now coredns

final_message: "Infra DNS + NTP listos para SNO."