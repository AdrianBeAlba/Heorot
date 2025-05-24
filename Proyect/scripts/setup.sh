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
    "imports"  # Para exportaciones e importaciones de estructuras
    "scripts"  # Almacena los scripts del sistema
)

# Crear las carpetas si no existen
echo "Creando estructura de directorios..."
for dir in "${directorios[@]}"; do
    mkdir -p "$dir"
    echo "Creado $dir"
done

echo "Estructura de directorios creada."

# Crear archivos CSV iniciales si no existen
touch temp/redes.csv
echo "default,192.168.99.0,255.255.255.0" > temp/redes.csv

docker network create default

touch temp/servidores.csv

touch temp/roles.csv

echo "Archivos CSV iniciales creados."

# Crear rol de Apache con Ansible Galaxy
echo "Creando rol de Apache con Ansible Galaxy..."
ansible-galaxy init roles/apache

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

echo "Rol de Apache creado y configurado."

echo "apache,roles/apache" >> temp/roles.csv

echo "Rol apache configurado"

# Instalar dependencias necesarias
echo "Instalando dependencias..."
sudo apt update && sudo apt install -y docker.io docker-compose ansible zip unzip ssh util-linux bsdmainutils

echo "Setup inicial completado con éxito."
