#!/bin/bash

##############################################
# Heorot - Gestión de Servidores
# ----------------------------------------------
# Autor: Adrian Bejarano Albarracín
# Fecha: 27/03/2025
# Descripción: Script para gestionar servidores en Heorot
##############################################

source scripts/utils.sh
source scripts/redes.sh


SERVIDORES_CSV="temp/servidores.csv"
COMPOSE_DIR="compose"
REDES_CSV="temp/redes.csv"



function listar_servidores() {
    echo "Listado de servidores:"
    echo "Nombre           Red              Estado"
    echo "-------------------------------------------"
    awk -F',' '{ printf "%-17s %-17s %-10s\n", $1, $2, $3 }' "$SERVIDORES_CSV"
}

crear_servidor() {
    read -p "Nombre del servidor: " nombre
    listar_redes
    read -p "Red (dejar vacío para usar 'heorot_default'): " red
    [[ -z "$red" ]] && red="heorot_default"

    if ! grep -q "^$red," "$REDES_CSV"; then
        echo "Error: La red especificada no existe."
        return 1
    fi

    # Crear estructura para el contenedor
    mkdir -p "$COMPOSE_DIR/$nombre"
    # Crear carpeta de volúmenes
    mkdir -p "$COMPOSE_DIR/$nombre/volumes/"

    cat > "$COMPOSE_DIR/$nombre/docker-compose.yml" <<EOL
version: '3.9'
services:
  $nombre:
    image: debian:latest
    container_name: $nombre
    networks:
      - $red
    tty: true
    stdin_open: true
    ports:
      - "22"
    command: >
      bash -c "apt update &&
               apt install -y python3 openssh-server sudo &&
               useradd -m ansible -s /bin/bash &&
               echo 'ansible:ansible' | chpasswd &&
               echo 'ansible ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers &&
               mkdir -p /var/run/sshd &&
               /usr/sbin/sshd -D"

networks:
  $red:
    external: true
EOL

    echo "$nombre,$red,activo" >> "$SERVIDORES_CSV"

    docker compose -f "$COMPOSE_DIR/$nombre/docker-compose.yml" up -d

    ansible_disponible $nombre
    copiar_clave_ssh $nombre
    echo "Servidor $nombre creado y activado."
}



# Deprecated
# function modificar_servidor() {
#     listar_servidores
#     read -p "Nombre del servidor a modificar: " nombre

#     if ! grep -q "^$nombre," "$SERVIDORES_CSV"; then
#         echo "Error: El servidor no existe."
#         return 1
#     fi

#     read -p "Nuevo nombre (dejar vacío para mantener actual): " nuevo_nombre
#     read -p "Nueva red (dejar vacío para mantener actual): " nueva_red

#     nuevo_nombre="${nuevo_nombre:-$nombre}"
#     vieja_red=$(grep "^$nombre," "$SERVIDORES_CSV" | cut -d, -f2)
#     nueva_red="${nueva_red:-$vieja_red}"

#     if ! grep -q "^$nueva_red," "$REDES_CSV"; then
#         echo "Error: La red especificada no existe."
#         return 1
#     fi

#     estado_actual=$(grep "^$nombre," "$SERVIDORES_CSV" | cut -d, -f3)
#     sed -i "s/^$nombre,.*/$nuevo_nombre,$nueva_red,$estado_actual/" "$SERVIDORES_CSV"

#     mv "$COMPOSE_DIR/$nombre" "$COMPOSE_DIR/$nuevo_nombre"
#     sed -i "s/container_name: $nombre/container_name: $nuevo_nombre/" "$COMPOSE_DIR/$nuevo_nombre/docker-compose.yml"
#     sed -i "s/$nombre:/$nuevo_nombre:/" "$COMPOSE_DIR/$nuevo_nombre/docker-compose.yml"

#     echo "Servidor modificado correctamente."
# }

eliminar_servidor() {
    listar_servidores
    read -p "Nombre del servidor a eliminar: " nombre

    if ! grep -q "^$nombre," "$SERVIDORES_CSV"; then
        echo "Error: El servidor no existe."
        return 1
    fi

    docker compose -f "$COMPOSE_DIR/$nombre/docker-compose.yml" down

    # Eliminar contenedores/volúmenes huérfanos en Docker (solo si es seguro)
    echo "Eliminando volúmenes de Docker no usados..."
    docker volume prune -f > /dev/null

    sed -i "/^$nombre,/d" "$SERVIDORES_CSV"
    rm -rf "$COMPOSE_DIR/$nombre"

    echo "Servidor $nombre eliminado correctamente."
}

toggle_estado_servidor() {
    listar_servidores
    read -p "Nombre del servidor a activar/desactivar: " nombre

    if ! grep -q "^$nombre," "$SERVIDORES_CSV"; then
        echo "Error: El servidor no existe."
        return 1
    fi

    estado_actual=$(grep "^$nombre," "$SERVIDORES_CSV" | cut -d, -f3)
    compose_file="$COMPOSE_DIR/$nombre/docker-compose.yml"

    if [[ "$estado_actual" == "activo" ]]; then
        docker compose -f "$compose_file" pause
        nuevo_estado="inactivo"
    else
        docker compose -f "$compose_file" unpause || docker compose -f "$compose_file" up -d
        nuevo_estado="activo"
    fi

    red_asociada=$(grep "^$nombre," "$SERVIDORES_CSV" | cut -d',' -f2)
    sed -i "s/^$nombre,[^,]*,[^,]*/$nombre,$red_asociada,$nuevo_estado/" "$SERVIDORES_CSV"
    echo "Estado del servidor $nombre cambiado a $nuevo_estado."
}

menu_servidores() {
    while true; do
        echo ""
        echo "==== Gestión de Servidores ===="
        echo "1. Listar servidores"
        echo "2. Crear servidor"
        echo "3. Eliminar servidor"
        echo "4. Activar/Desactivar servidor"
        echo "9. Volver al menú principal"
        read -p "Seleccione una opción: " opcion

        case "$opcion" in
            1) listar_servidores ;;
            2) crear_servidor ;;
            3) eliminar_servidor ;;
            4) toggle_estado_servidor ;;
            9) break ;;
            *) echo "Opción no válida" ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    menu_servidores
fi
