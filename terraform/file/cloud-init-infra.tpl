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
      dns=${dns1}
      may-fail=false

      [ipv6]
      method=ignore

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

runcmd:
  - nmcli connection reload
  - systemctl enable --now chronyd
  - dnf install -y firewalld bind-utils

  - firewall-cmd --permanent --add-port=53/tcp
  - firewall-cmd --permanent --add-port=53/udp
  - firewall-cmd --reload

  - curl -L -o /usr/local/bin/coredns \
      https://github.com/coredns/coredns/releases/download/v1.13.1/coredns_1.13.1_linux_amd64.tgz
  - chmod +x /usr/local/bin/coredns

  - systemctl daemon-reload
  - systemctl enable --now coredns

final_message: "Infra OKD DNS funcionando correctamente."