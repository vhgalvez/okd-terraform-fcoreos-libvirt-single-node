#cloud-config
hostname: ${hostname}
manage_etc_hosts: false
timezone: ${timezone}

ntp:
  enabled: true
  servers:
    - 10.66.0.1   # Rocky Linux host (NTP local)

ssh_pwauth: false
disable_root: false

users:
  - default

  - name: root
    ssh_authorized_keys:
      - ${ssh_keys}

  - name: core
    gecos: "Core User"
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    groups: [wheel]
    shell: /bin/bash
    lock_passwd: false
    ssh_authorized_keys:
      - ${ssh_keys}

###########################################################
# WRITE FILES
###########################################################

write_files:

  ###########################################################
  # NetworkManager — IP fija + DNS local CoreDNS
  ###########################################################
  - path: /etc/NetworkManager/system-connections/eth0.nmconnection
    permissions: "0600"
    content: |
      [connection]
      id=eth0
      type=ethernet
      interface-name=eth0
      autoconnect=true

      [ipv4]
      method=manual
      address1=${ip}/24,${gateway}
      dns=${ip}
      dns-search=${cluster_name}.${cluster_domain}
      may-fail=false

      [ipv6]
      method=ignore

  ###########################################################
  # /etc/hosts dinámico
  ###########################################################
  - path: /usr/local/bin/set-hosts.sh
    permissions: "0755"
    content: |
      #!/bin/bash
      {
        echo "127.0.0.1 localhost"
        echo "::1 localhost"
        echo "${ip} ${hostname} ${short_hostname}"
      } > /etc/hosts

  ###########################################################
  # sysctl
  ###########################################################
  - path: /etc/sysctl.d/99-custom.conf
    permissions: "0644"
    content: |
      net.ipv4.ip_forward = 1
      net.ipv4.ip_nonlocal_bind = 1
      net.ipv4.conf.all.forwarding = 1

  ###########################################################
  # NetworkManager — sin resolved
  ###########################################################
  - path: /etc/NetworkManager/conf.d/dns.conf
    permissions: "0644"
    content: |
      [main]
      dns=none

  ###########################################################
  # CoreDNS — Configuración SNO
  ###########################################################
  - path: /etc/coredns/Corefile
    permissions: "0644"
    content: |
      ${cluster_name}.${cluster_domain}. {
        file /etc/coredns/db.sno
      }
      . {
        forward . 8.8.8.8 1.1.1.1
      }

  ###########################################################
  # Zona DNS mínima para OKD SNO
  ###########################################################
  - path: /etc/coredns/db.sno
    permissions: "0644"
    content: |
      $ORIGIN ${cluster_name}.${cluster_domain}.
      @   IN SOA dns.${cluster_name}.${cluster_domain}. admin.${cluster_name}.${cluster_domain}. (
              2025010101
              7200
              3600
              1209600
              3600 )
      @       IN NS dns.${cluster_name}.${cluster_domain}.
      dns     IN A ${ip}

      # SNO required records
      api     IN A ${ip}
      api-int IN A ${ip}
      ${cluster_name} IN A ${ip}

  ###########################################################
  # CoreDNS systemd service
  ###########################################################
  - path: /etc/systemd/system/coredns.service
    permissions: "0644"
    content: |
      [Unit]
      Description=CoreDNS
      After=network-online.target
      Wants=network-online.target

      [Service]
      ExecStart=/usr/local/bin/coredns -conf=/etc/coredns/Corefile
      Restart=always
      LimitNOFILE=1048576

      [Install]
      WantedBy=multi-user.target


###########################################################
# RUNCMD
###########################################################
runcmd:
  - dnf install -y firewalld chrony curl tar bind-utils policycoreutils-python-utils

  - /usr/local/bin/set-hosts.sh

  # Swap opcional
  - fallocate -l 4G /swapfile
  - chmod 600 /swapfile
  - mkswap /swapfile
  - swapon /swapfile
  - echo "/swapfile none swap sw 0 0" >> /etc/fstab

  # Chrony NTP
  - systemctl enable --now chronyd
  - sed -i 's/^pool.*/server 10.66.0.1 iburst/' /etc/chrony.conf
  - echo "allow 10.66.0.0/24" >> /etc/chrony.conf
  - systemctl restart chronyd

  # resolv.conf → apuntar al DNS local
  - rm -f /etc/resolv.conf
  - printf "nameserver ${ip}\nsearch ${cluster_name}.${cluster_domain}\n" > /etc/resolv.conf

  # CoreDNS
  - mkdir -p /etc/coredns
  - curl -L -o /tmp/coredns.tgz https://github.com/coredns/coredns/releases/download/v1.13.1/coredns_1.13.1_linux_amd64.tgz
  - tar -xzf /tmp/coredns.tgz -C /usr/local/bin
  - chmod +x /usr/local/bin/coredns

  - systemctl daemon-reload
  - systemctl enable --now firewalld chronyd coredns

  - firewall-cmd --permanent --add-port=53/tcp
  - firewall-cmd --permanent --add-port=53/udp
  - firewall-cmd --reload

final_message: "DNS + NTP + Networking SNO funcionando."
