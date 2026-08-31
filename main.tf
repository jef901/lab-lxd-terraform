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

# 1. Red privada de prácticas
resource "lxd_network" "red_practica" {
  name = "red-tf"
  config = {
    "ipv4.address"  = "10.0.20.1/24"
    "ipv4.nat"      = "true"
    "ipv4.firewall" = "false"
    "ipv6.address"  = "none"
  }
}

# Perfil especial para habilitar Docker Anidado
resource "lxd_profile" "perfil_docker" {
  name = "perfil-docker"

  config = {
    "security.nesting"    = "true"  # Permite anidación
    "security.privileged" = "true"  # Da privilegios para el motor de Docker
    
    # Script automático para instalar Docker al nacer
    "user.user-data" = <<EOF
#cloud-config
package_update: true
packages:
  - docker.io
runcmd:
  - echo "nameserver 8.8.8.8" > /etc/resolv.conf
  - systemctl enable --now docker
EOF
  }
}

# 2. Nodo de Base de Datos preparado para Docker (10.0.20.10)
resource "lxd_instance" "srv_db" {
  name      = "srv-db-tf"
  image     = "ubuntu:24.04"
  type      = "container"
  profiles  = ["default", lxd_profile.perfil_docker.name]

  device {
    name    = "eth0"
    type    = "nic"
    properties = {
      network      = lxd_network.red_practica.name
      "ipv4.address" = "10.0.20.10"
    }
  }
}

# 3. Dos Nodos Web preparados para Docker (10.0.20.21 y 10.0.20.22)
resource "lxd_instance" "srv_web" {
  count     = 2
  name      = "srv-web-tf-${count.index + 1}"
  image     = "ubuntu:24.04"
  type      = "container"
  profiles  = ["default", lxd_profile.perfil_docker.name]

  device {
    name    = "eth0"
    type    = "nic"
    properties = {
      network      = lxd_network.red_practica.name
      "ipv4.address" = "10.0.20.2${count.index + 1}"
    }
  }
}

# 4. Nodo Balanceador preparado para Docker (10.0.20.30)
resource "lxd_instance" "srv_lb" {
  name      = "srv-lb-tf"
  image     = "ubuntu:24.04"
  type      = "container"
  profiles  = ["default", lxd_profile.perfil_docker.name]

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
