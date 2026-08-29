#!/bin/bash

echo "=== Configurando Red de Prácticas LXD en WSL ==="

# 1. Habilitar el reenvío de paquetes en el Kernel
sudo sysctl -w net.ipv4.ip_forward=1

# 2. Permitir el tráfico en el Firewall para la red de Terraform (red-tf)
sudo iptables -A FORWARD -i red-tf -j ACCEPT
sudo iptables -A FORWARD -o red-tf -j ACCEPT

# 3. Aplicar el enmascaramiento NAT para la subred de Terraform
sudo iptables -t nat -A POSTROUTING -s 10.0.20.0/24 -j MASQUERADE

echo "=== ¡Red lista para usar con Terraform! ==="
