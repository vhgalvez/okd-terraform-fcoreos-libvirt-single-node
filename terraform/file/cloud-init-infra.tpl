#cloud-config
hostname: ${hostname}
manage_etc_hosts: true
timezone: ${timezone}

ssh_pwauth: false
disable_root: false

users:
  - default
  - name: core
    gecos: "Core User"
    groups: [wheel]
    shell: /bin/bash
    lock_passwd: false
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    ssh_authorized_keys:
      - ${ssh_keys}

  - name: root
    ssh_authorized_keys:
      - ${ssh_keys}

package_update: true
package_upgrade: true

packages:
  - chrony
  - firewalld
  - bind-utils
  - tar
  - curl

write_files:

  ###########################################################
  # CoreDNS – Corefile corregido
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
  # Zona DNS del cluster SNO
  ###########################################################
  - path: /etc/coredns/db.okd
    permissions: "0644"
    content: |
      $ORIGIN ${cluster_name}.${cluster_domain}.
      @ IN SOA infra.${cluster_name}.${cluster_domain}. admin.${cluster_name}.${cluster_domain}. (
          2025010101 7200 3600 1209600 3600 )

      @       IN NS infra.${cluster_name}.${cluster_domain}.
      infra   IN A ${ip}

      api     IN A ${sno_ip}
      api-int IN A ${sno_ip}
      ${cluster_name} IN A ${sno_ip}

  ###########################################################
  # CoreDNS systemd unit CORREGIDO
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
      LimitNOFILE=1048576

      [Install]
      WantedBy=multi-user.target

runcmd:
  - systemctl enable --now chronyd
  - sed -i 's/^pool.*/server 10.66.0.1 iburst/' /etc/chrony.conf
  - echo "allow 10.66.0.0/24" >> /etc/chrony.conf
  - systemctl restart chronyd

  # Resolver local
  - rm -f /etc/resolv.conf
  - printf "nameserver ${ip}\nsearch ${cluster_name}.${cluster_domain}\n" > /etc/resolv.conf

  # Descargar CoreDNS correctamente
  - mkdir -p /etc/coredns
  - cd /tmp
  - curl -LO https://github.com/coredns/coredns/releases/download/v1.13.1/coredns_1.13.1_linux_amd64.tgz
  - tar -xzf coredns_1.13.1_linux_amd64.tgz
  - mv coredns /usr/local/bin/
  - chmod +x /usr/local/bin/coredns

  # Activar servicios
  - systemctl daemon-reload
  - systemctl enable --now firewalld coredns

  # Abrir puertos DNS
  - firewall-cmd --permanent --add-port=53/tcp
  - firewall-cmd --permanent --add-port=53/udp
  - firewall-cmd --reload

final_message: "Infra DNS + NTP listos para SNO."