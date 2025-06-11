#!/bin/bash

##############################################
# Heorot - Setup Inicial
# ----------------------------------------------
# Autor: Adrian Bejarano Albarracín
# Fecha: 27/03/2025
# Descripción: Este script configura el entorno inicial para
#              el correcto funcionamiento de Heorot. Crea la 
#              estructura de directorios y archivos necesarios,
#              e instala dependencias clave.
##############################################

# Definir las carpetas principales
directorios=(
    "compose"  # Almacena los docker-compose generados
    "roles"    # Contiene los roles de Ansible
    "temp"     # Archivos temporales de ejecución
    "imports"  # Para importaciones de estructuras
    "scripts"  # Almacena los scripts del sistema
    "exports"  # Almacena exportaciones
)

source scripts/utils.sh

# Instalar dependencias necesarias
echo "Instalando dependencias..."
sudo apt install curl
# Quitar versiones previas de Docker (si las hay)
sudo apt remove -y docker docker.io docker-doc docker-compose || true

# Añadir repositorio oficial de Docker
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update

# Instalar Docker 27.5.1 + plugins necesarios
sudo apt install -y \
  docker-ce=5:27.5.1~ubuntu.$(lsb_release -rs)~$(lsb_release -cs) \
  docker-ce-cli=5:27.5.1~ubuntu.$(lsb_release -rs)~$(lsb_release -cs) \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

# Instalar dependencias adicionales
sudo apt install -y  ansible ssh util-linux bsdmainutils

# Crear las carpetas si no existen
echo "Creando estructura de directorios..."
for dir in "${directorios[@]}"; do
    mkdir -p "$dir"
    echo "Creado $dir"
done

echo "Estructura de directorios creada."

# Crear archivos CSV iniciales si no existen
echo "Creando archivo redes.csv..."
mkdir -p temp
echo "heorot_default,192.168.99.0,255.255.255.0" > temp/redes.csv

echo "Creando red Docker 'heorot_default'..."
docker network create \
  --driver=bridge \
  --subnet=192.168.99.0/24 \
  heorot_default || echo "La red 'heorot_default' ya existe."

touch temp/servidores.csv

touch temp/roles.csv

echo "Archivos CSV iniciales creados."

# Crear rol de Apache con Ansible Galaxy
echo "Creando rol de Apache con Ansible Galaxy..."
crear_rolPorNombre apache
# Definir tareas para instalar Apache y configurar un index.html
echo "---" > roles/apache/tasks/main.yml
echo "- name: Instalar Apache" >> roles/apache/tasks/main.yml
echo "  apt:" >> roles/apache/tasks/main.yml
echo "    name: apache2" >> roles/apache/tasks/main.yml
echo "    state: present" >> roles/apache/tasks/main.yml

echo "- name: Copiar archivo index.html" >> roles/apache/tasks/main.yml
echo "  copy:" >> roles/apache/tasks/main.yml
echo "    src: index.html" >> roles/apache/tasks/main.yml
echo "    dest: /var/www/html/index.html" >> roles/apache/tasks/main.yml
echo "    mode: '0644'" >> roles/apache/tasks/main.yml

echo "- name: Reiniciar Apache" >> roles/apache/tasks/main.yml
echo "  service:" >> roles/apache/tasks/main.yml
echo "    name: apache2" >> roles/apache/tasks/main.yml
echo "    state: restarted" >> roles/apache/tasks/main.yml

# Crear archivo index.html
echo "Bienvenido a Heorot!" > roles/apache/files/index.html
cat roles/apache/files/index.html

cat > roles/apache/meta/volumes.yml <<EOF
---
volumes:
  - container_path: /var/www/html
    host_path: var/www/html
  - container_path: /etc/apache2
    host_path: etc/apache2
EOF

cat > roles/apache/meta/services.conf <<EOF
# Supervisord config for apache2
[program:apache2]
command=/usr/sbin/apachectl -D FOREGROUND
autostart=true
autorestart=true
stderr_logfile=/var/log/apache2.err.log
stdout_logfile=/var/log/apache2.out.log
EOF

echo "Rol de Apache creado y configurado."

echo "Setup inicial completado con éxito."
