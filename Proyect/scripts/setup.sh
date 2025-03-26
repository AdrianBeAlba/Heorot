#!/bin/bash

##############################################
# Heorot - Setup Inicial
# ----------------------------------------------
# Autor: [Tu Nombre]
# Fecha: [Fecha Actual]
# Descripción: Este script configura el entorno inicial para
#              el correcto funcionamiento de Heorot. Crea la 
#              estructura de directorios y archivos necesarios,
#              e instala dependencias clave.
##############################################

# Definir las carpetas principales
directorios=(
    "compose"  # Almacena los docker-compose generados
    "roles"    # Contiene los roles de Ansible
    "redes"    # CSV con las redes creadas
    "temp"     # Archivos temporales de ejecución
    "imports"  # Para exportaciones e importaciones de estructuras
    "scripts"  # Almacena los scripts del sistema
)

# Crear las carpetas si no existen
echo "Creando estructura de directorios..."
for dir in "${directorios[@]}"; do
    mkdir -p "$dir"
done

echo "Estructura de directorios creada."

# Crear archivos CSV iniciales si no existen
touch redes/redes.csv

echo "name" > redes/redes.csv
echo "default" >> redes/redes.csv

touch temp/servidores.csv
echo "name,network" > temp/servidores.csv

touch roles/roles.csv
echo "name,path" > roles/roles.csv

echo "Archivos CSV iniciales creados."

# Instalar dependencias necesarias
echo "Instalando dependencias..."
sudo apt update && sudo apt install -y docker.io docker-compose ansible zip unzip

echo "Setup inicial completado con éxito."
