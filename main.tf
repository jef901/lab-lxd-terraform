terraform {
  required_providers {
    lxd = {
      source  = "terraform-lxd/lxd"
      version = "2.4.0"
    }
  }
}

provider "lxd" {
  accept_remote_certificate = true
}

# 1. Red privada
resource "lxd_network" "red_practica" {
  name = "red-tf"
  config = {
    "ipv4.address"  = "10.0.20.1/24"
    "ipv4.nat"      = "true"
    "ipv4.firewall" = "false"
    "ipv6.address"  = "none"
  }
}

# Perfil base para habilitar SSH y Cloud-Init limpio en todos los nodos
resource "lxd_profile" "perfil_ansible" {
  name = "perfil-ansible"

  config = {
    # Instalamos SSH al nacer para que Ansible pueda conectarse
    "user.user-data" = <<EOF
#cloud-config
package_update: true
packages:
  - openssh-server
runcmd:
  - echo "nameserver 8.8.8.8" > /etc/resolv.conf
  - systemctl enable --now ssh
  # Permitir acceso directo como root para facilitar la práctica local
  - sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
  - sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
  - echo "root:PasswordSegura123" | chpasswd
  - systemctl restart ssh
EOF
  }
}

# 2. Servidor de Base de Datos Vacío (10.0.20.10)
resource "lxd_instance" "srv_db" {
  name      = "srv-db-tf"
  image     = "ubuntu:24.04"
  type      = "container"
  profiles  = ["default", lxd_profile.perfil_ansible.name]

  device {
    name    = "eth0"
    type    = "nic"
    properties = {
      network      = lxd_network.red_practica.name
      "ipv4.address" = "10.0.20.10"
    }
  }
}

# 3. Dos Servidores Web Vacíos (10.0.20.21 y 10.0.20.22)
resource "lxd_instance" "srv_web" {
  count     = 2
  name      = "srv-web-tf-${count.index + 1}"
  image     = "ubuntu:24.04"
  type      = "container"
  profiles  = ["default", lxd_profile.perfil_ansible.name]

  device {
    name    = "eth0"
    type    = "nic"
    properties = {
      network      = lxd_network.red_practica.name
      "ipv4.address" = "10.0.20.2${count.index + 1}"
    }
  }
}

# 4. Balanceador de Carga Vacío (10.0.20.30)
resource "lxd_instance" "srv_lb" {
  name      = "srv-lb-tf"
  image     = "ubuntu:24.04"
  type      = "container"
  profiles  = ["default", lxd_profile.perfil_ansible.name]

  device {
    name    = "eth0"
    type    = "nic"
    properties = {
      network      = lxd_network.red_practica.name
      "ipv4.address" = "10.0.20.30"
    }
  }

  device {
    name = "puerto8080"
    type = "proxy"
    properties = {
      listen  = "tcp:0.0.0.0:8080"
      connect = "tcp:127.0.0.1:80"
    }
  }
}
