#cloud-config
hostname: ${hostname}
manage_etc_hosts: true
timezone: ${timezone}

ssh_pwauth: false
disable_root: false

users:
  - default
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
  # CoreDNS – zona para SNO
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

  - path: /etc/coredns/db.okd
    permissions: "0644"
    content: |
      $ORIGIN ${cluster_name}.${cluster_domain}.
      @ IN SOA infra.${cluster_name}.${cluster_domain}. admin.${cluster_name}.${cluster_domain}. (
          2025010101 7200 3600 1209600 3600 )

      @       IN NS infra.${cluster_name}.${cluster_domain}.
      infra   IN A ${ip}

      # Registros necesarios para SNO:
      api     IN A ${sno_ip}
      api-int IN A ${sno_ip}
      ${cluster_name} IN A ${sno_ip}

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
      LimitNOFILE=1048576

      [Install]
      WantedBy=multi-user.target

runcmd:
  # NTP: usar 10.66.0.1 (host Rocky)
  - systemctl enable --now chronyd
  - sed -i 's/^pool.*/server 10.66.0.1 iburst/' /etc/chrony.conf
  - echo "allow 10.66.0.0/24" >> /etc/chrony.conf
  - systemctl restart chronyd

  # Resolver del infra: él mismo
  - rm -f /etc/resolv.conf
  - printf "nameserver ${ip}\nsearch ${cluster_name}.${cluster_domain}\n" > /etc/resolv.conf

  # CoreDNS binario
  - mkdir -p /etc/coredns
  - curl -L -o /tmp/coredns.tgz https://github.com/coredns/coredns/releases/download/v1.13.1/coredns_1.13.1_linux_amd64.tgz
  - tar -xzf /tmp/coredns.tgz -C /usr/local/bin
  - chmod +x /usr/local/bin/coredns

  # Firewall + servicios
  - systemctl daemon-reload
  - systemctl enable --now firewalld chronyd coredns

  - firewall-cmd --permanent --add-port=53/tcp
  - firewall-cmd --permanent --add-port=53/udp
  - firewall-cmd --reload

final_message: "Infra DNS + NTP listos para SNO."
