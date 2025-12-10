# OKD 4.x SNO – Terraform + Fedora CoreOS + Libvirt (0.8.3)
Proyecto completo, automatizado y listo para desplegar un **Single Node OpenShift (SNO)** usando:

- **Fedora CoreOS**
- **Ignition generada por openshift-install**
- **Terraform + Libvirt (provider 0.8.3)**
- **DNS interno con dnsmasq**
- **Scripts automáticos de deploy / destroy / install-tools**

Este proyecto está optimizado para entornos de laboratorio, homelab y nodos de bajo coste donde se desea ejecutar OpenShift/OKD en un único nodo.

---

## 🚀 Características principales

### ✔ 100% SNO (Single Node OpenShift)
- Un solo nodo master
- 0 workers
- No requiere bootstrap node
- Todo el cluster corre dentro de un único host Fedora CoreOS

### ✔ Completamente automatizado
Incluye scripts para:

- Instalar herramientas (`oc`, `kubectl`, `openshift-install`)
- Generar Ignition
- Aplicar Terraform
- Destruir el cluster y limpiar estado

### ✔ Compatible con libvirt 0.8.3 y Terraform 1.14.x  
### ✔ DNS funcional para API, API-INT y etcd (SRV)

---

## 📂 Estructura del proyecto

```
okd-terraform-fcoreos-libvirt-single-node/
│
├── install-config/
│   └── install-config.yaml
│
├── terraform/
│   ├── main.tf
│   ├── network.tf
│   ├── variables.tf
│   ├── vm-coreos-sno.tf
│   ├── outputs.tf
│   └── terraform.tfvars
│
├── dns/
│   └── dnsmasq.conf
│
├── scripts/
│   ├── install_okd_tools.sh
│   ├── deploy.sh
│   ├── destroy.sh
│   └── uninstall_okd.sh
│
└── generated/   (se crea automáticamente)
    ├── install-config.yaml
    ├── ignition/
    └── auth/
```

---

## 🧰 Dependencias

Instala en tu host:

- Terraform ≥ 1.14.1  
- Provider Libvirt = 0.8.3  
- KVM + QEMU + Libvirt  
- dnsmasq  
- Fedora CoreOS QCOW2 local  
- Linux host: Rocky / Alma / Fedora / Ubuntu  

---

## ⚙️ 1. Instalar herramientas de OKD

```bash
sudo ./scripts/install_okd_tools.sh
```

Esto instala:

- `oc`
- `kubectl`
- `openshift-install`

En `/opt/bin/`.

---

## ⚙️ 2. Preparar la configuración

Edita:

```
install-config/install-config.yaml
terraform/terraform.tfvars
```

Ejemplo de red:

```
10.56.0.0/24
```

El nodo SNO debe tener IP fija.

---

## 🚀 3. Desplegar el cluster

```bash
./scripts/deploy.sh
```

Luego:

```bash
export KUBECONFIG=auth/kubeconfig
oc get nodes
```

---

## 🗑️ 4. Destruir el cluster

```bash
./scripts/destroy.sh
```

---

## 🧹 5. Desinstalar herramientas OKD

```bash
sudo ./scripts/uninstall_okd.sh
```

---

## 🔧 DNS requerido (dnsmasq)

```conf
server=1.1.1.1
server=8.8.8.8
address=/okd.okd.local/10.56.0.10
address=/api.okd.okd.local/10.56.0.10
address=/api-int.okd.okd.local/10.56.0.10
srv-host=_etcd-server-ssl._tcp.okd.okd.local,okd.okd.local,2380,0,10
```

---

## 🖥️ Acceso a la consola

```
https://console-openshift-console.apps.okd.okd.local/
```

Usuario:

```
kubeadmin
```

Password:

```
generated/auth/kubeadmin-password
```

---

## ❤️ Autor

Proyecto generado automáticamente para **Victor Hugo Gálvez Sastoque**.
