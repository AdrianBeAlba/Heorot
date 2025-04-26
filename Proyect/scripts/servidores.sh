#!/bin/bash

##############################################
# Heorot - Setup Inicial
# ----------------------------------------------
# Autor: Adrian Bejarano Albarracín
# Fecha: 27/03/2025
# Descripción: Script para gestionar servidores en Heorot
##############################################


# Cargar configuraciones y funciones auxiliares
source scripts/utils.sh

SERVIDORES_CSV="temp/servidores.csv"
COMPOSE_DIR="compose"
REDES_CSV="redes/redes.csv"

function listar_servidores() {
    clear
    echo "Listado de servidores:"
    column -s, -t < "$SERVIDORES_CSV"
}

function crear_servidor() {
    read -p "Nombre del servidor: " nombre
    read -p "Red (dejar vacío para usar 'default'): " red
    
    if [[ -z "$red" ]]; then
        red="default"
    fi
    
    if ! grep -q "^$red," "$REDES_CSV"; then
        echo "Error: La red especificada no existe."
        return 1
    fi
    
    mkdir -p "$COMPOSE_DIR/$nombre"
    cat > "$COMPOSE_DIR/$nombre/docker-compose.yml" <<EOL
version: '3'
services:
  $nombre:
    image: debian:latest
    container_name: $nombre
    networks:
      - $red
      - host_network
    tty: true
    stdin_open: true
EOL
    
    echo "$nombre,$red" >> "$SERVIDORES_CSV"
    echo "Servidor $nombre creado correctamente."
}

function modificar_servidor() {
    listar_servidores
    read -p "Nombre del servidor a modificar: " nombre
    
    if ! grep -q "^$nombre," "$SERVIDORES_CSV"; then
        echo "Error: El servidor no existe."
        return 1
    fi
    
    read -p "Nuevo nombre (dejar vacío para mantener actual): " nuevo_nombre
    read -p "Nueva red (dejar vacío para mantener actual): " nueva_red
    
    if [[ -z "$nuevo_nombre" ]]; then
        nuevo_nombre="$nombre"
    fi
    
    if [[ ! -z "$nueva_red" ]] && ! grep -q "^$nueva_red," "$REDES_CSV"; then
        echo "Error: La red especificada no existe."
        return 1
    fi
    
    sed -i "s/^$nombre,.*/$nuevo_nombre,${nueva_red:-$(grep "^$nombre," "$SERVIDORES_CSV" | cut -d, -f2)}/" "$SERVIDORES_CSV"
    mv "$COMPOSE_DIR/$nombre" "$COMPOSE_DIR/$nuevo_nombre"
    echo "Servidor modificado correctamente."
}

function eliminar_servidor() {
    listar_servidores
    read -p "Nombre del servidor a eliminar: " nombre
    
    if ! grep -q "^$nombre," "$SERVIDORES_CSV"; then
        echo "Error: El servidor no existe."
        return 1
    fi
    
    sed -i "/^$nombre,/d" "$SERVIDORES_CSV"
    rm -rf "$COMPOSE_DIR/$nombre"
    echo "Servidor $nombre eliminado correctamente."
}

function menu_servidores() {
    while true; do
        
        echo "1. Listar servidores"
        echo "2. Crear servidor"
        echo "3. Modificar servidor"
        echo "4. Eliminar servidor"
        echo "5. Volver al menú principal"
        read -p "Seleccione una opción: " opcion
        
        case "$opcion" in
            1) listar_servidores ;;
            2) crear_servidor ;;
            3) modificar_servidor ;;
            4) eliminar_servidor ;;
            5) break ;;
            *) echo "Opción no válida" ;;
        esac
    done
}

menu_servidores
