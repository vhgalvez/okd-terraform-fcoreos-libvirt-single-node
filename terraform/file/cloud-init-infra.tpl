#cloud-config
hostname: ${hostname}
manage_etc_hosts: false
timezone: ${timezone}

ssh_pwauth: false
disable_root: false

users:
  - default

  - name: core
    gecos: "Core User"
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    groups: [wheel]
    shell: /bin/bash
    lock_passwd: false
    ssh_authorized_keys:
      - ${ssh_keys}

  - name: root
    ssh_authorized_keys:
      - ${ssh_keys}

###########################################################
# WRITE FILES
###########################################################

write_files:

  ###########################################################
  # NetworkManager – IP fija + DNS (NECESARIO)
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
      dns=${dns1};${dns2}
      dns-search=${cluster_name}.${cluster_domain}
      may-fail=false

      [ipv6]
      method=ignore


  ###########################################################
  # NetworkManager: NO tocar resolv.conf
  ###########################################################
  - path: /etc/NetworkManager/conf.d/dns-none.conf
    permissions: "0644"
    content: |
      [main]
      dns=none


  ###########################################################
  # CoreDNS – zona DNS mínima
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
  # CoreDNS Corefile
  ###########################################################
  - path: /etc/coredns/Corefile
    permissions: "0644"
    content: |
      ${cluster_name}.${cluster_domain}. {
        file /etc/coredns/db.okd
      }

      . {
        forward . 8.8.8.8 1.1.1.1
      }


  ###########################################################
  # CoreDNS systemd unit
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
      LimitNOFILE=1048576

      [Install]
      WantedBy=multi-user.target


###########################################################
# RUNCMD
###########################################################
runcmd:

  # Aplicar IP fija de NetworkManager
  - nmcli connection reload
  - nmcli connection down eth0 || true
  - nmcli connection up eth0

  # Paquetes
  - dnf install -y chrony firewalld curl tar bind-utils

  # NTP
  - systemctl enable --now chronyd
  - sed -i 's/^pool.*/server ${gateway} iburst/' /etc/chrony.conf
  - systemctl restart chronyd

  # resolv.conf manual
  - rm -f /etc/resolv.conf
  - printf "nameserver ${dns1}\nnameserver ${dns2}\nsearch ${cluster_name}.${cluster_domain}\n" > /etc/resolv.conf

  # Instalar CoreDNS
  - mkdir -p /etc/coredns
  - curl -L -o /tmp/coredns.tgz https://github.com/coredns/coredns/releases/download/v1.13.1/coredns_1.13.1_linux_amd64.tgz
  - tar -xzf /tmp/coredns.tgz -C /usr/local/bin
  - chmod +x /usr/local/bin/coredns

  # Firewall
  - systemctl enable --now firewalld
  - firewall-cmd --permanent --add-port=53/tcp
  - firewall-cmd --permanent --add-port=53/udp
  - firewall-cmd --reload

  # CoreDNS
  - systemctl daemon-reload
  - systemctl enable --now coredns

final_message: "Infra DNS + NTP funcionando correctamente."