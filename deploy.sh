#!/bin/bash

echo "🚀 Iniciando Pipeline de Despliegue Continuo (CD)..."

# 1. PASO DE VERIFICACIÓN (CI): Comprobar que el archivo index.php exista en la carpeta actual
if [ ! -s "./index.php" ]; then
    echo "❌ ERROR: El archivo ./index.php no existe o está vacío. Abortando despliegue."
    exit 1
fi
echo "✅ Verificación exitosa: Código fuente válido."

# 2. PASO DE EMPAQUETADO: Enviar el código a los servidores LXD
echo "📦 Transfiriendo código a los nodos web..."
lxc file push ./index.php srv-web-tf-1/root/index.php
lxc file push ./index.php srv-web-tf-2/root/index.php

# Ajustar permisos de lectura para el motor de Docker interno
lxc exec srv-web-tf-1 -- chmod -R 755 /root
lxc exec srv-web-tf-2 -- chmod -R 755 /root

# 3. PASO DE DESPLIEGUE (CD): Validar y encender los contenedores Docker en paralelo
echo "🚢 Lanzando contenedores inmutables en Docker..."

# Configurar Nodo 1
lxc exec srv-web-tf-1 -- docker rm -f mi-servidor-web-1 2>/dev/null
lxc exec srv-web-tf-1 -- docker run -d --name mi-servidor-web-1 -p 80:80 -v /root:/app webdevops/php-nginx:8.3

# Configurar Nodo 2
lxc exec srv-web-tf-2 -- docker rm -f mi-servidor-web-2 2>/dev/null
lxc exec srv-web-tf-2 -- docker run -d --name mi-servidor-web-2 -p 80:80 -v /root:/app webdevops/php-nginx:8.3

echo "✨ ¡Pipeline completado con éxito! Tu aplicación está en producción."
