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
    tmp_csv=$(mktemp)

while IFS=',' read -r nombre red estado; do
    # Saltar encabezados o líneas vacías
    [[ "$nombre" == "nombre" || -z "$nombre" ]] && continue

    if docker inspect "$nombre" &>/dev/null; then
        estado_actual=$(docker inspect -f '{{.State.Status}}' "$nombre")
        case "$estado_actual" in
            running)
                nuevo_estado="activo"
                ;;
            exited|created|paused|dead)
                nuevo_estado="inactivo"
                ;;
            *)
                nuevo_estado="desconocido"
                ;;
        esac
    else
        nuevo_estado="inactivo"
    fi

    echo "$nombre,$red,$nuevo_estado" >> "$tmp_csv"
done < "$SERVIDORES_CSV"

    mv "$tmp_csv" "$SERVIDORES_CSV"

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

    cat > "$COMPOSE_DIR/$nombre/docker-compose.yml" <<EOL
services:
  $nombre:
    image: antmelekhin/docker-systemd:debian-12
    container_name: $nombre
    privileged: true
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
    networks:
      - $red
    restart: always
    tty: true
    stdin_open: true
    ports:
      - "22"

networks:
  $red:
    external: true
EOL

    echo "$nombre,$red,activo" >> "$SERVIDORES_CSV"

    docker compose -f "$COMPOSE_DIR/$nombre/docker-compose.yml" up -d
    configurar_servidor $nombre
    ansible_disponible $nombre
    copiar_clave_ssh $nombre
    echo "Servidor $nombre creado y activado."
}


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

    if docker ps -a --format '{{.Names}}' | grep -q "^${nombre}$"; then
        if [[ "$estado_actual" == "activo" ]]; then
            docker pause "$nombre"
            nuevo_estado="inactivo"
        else
            docker unpause "$nombre"
            nuevo_estado="activo"
        fi

        red_asociada=$(grep "^$nombre," "$SERVIDORES_CSV" | cut -d',' -f2)
        sed -i "s/^$nombre,[^,]*,[^,]*/$nombre,$red_asociada,$nuevo_estado/" "$SERVIDORES_CSV"
        echo "Estado del servidor $nombre cambiado a $nuevo_estado."
    else
        echo "Error: No existe un contenedor con el nombre '$nombre'."
        return 1
    fi
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
