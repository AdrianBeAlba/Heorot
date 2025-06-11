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
    actualizar_lista
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
version: '3.9'
services:
  $nombre:
    container_name: $nombre
    build:
        context: .
        dockerfile: Dockerfile
    networks:
      - $red
    tty: true
    stdin_open: true
    ports:
      - "22"

networks:
  $red:
    external: true
EOL
    cat > "$COMPOSE_DIR/$nombre/Dockerfile" <<'EOL'
FROM debian:latest

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    if ! dpkg -s supervisor python3 openssh-server sudo > /dev/null 2>&1; then \
        apt-get install -y supervisor python3 openssh-server sudo; \
    else \
        echo "Packages already installed, skipping install"; \
    fi

RUN if ! id -u ansible > /dev/null 2>&1; then \
        useradd -m ansible -s /bin/bash; \
    else \
        echo "User ansible already exists, skipping useradd"; \
    fi && \
    echo 'ansible:ansible' | chpasswd && \
    grep -q '^ansible ALL=' /etc/sudoers || echo 'ansible ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    mkdir -p /var/run/sshd

# Add supervisord config
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Start supervisord
CMD ["/usr/bin/supervisord", "-n"]
EOL

    cat > "$COMPOSE_DIR/$nombre/supervisord.conf" <<EOL
[supervisord]
nodaemon=true

[program:sshd]
command=/usr/sbin/sshd -D -o MaxStartups=50:30:200
autostart=true
autorestart=true
stderr_logfile=/var/log/sshd.err.log
stdout_logfile=/var/log/sshd.out.log
EOL
    echo "$nombre,$red,activo" >> "$SERVIDORES_CSV"

    docker compose -f "$COMPOSE_DIR/$nombre/docker-compose.yml" up --build -d

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

    # Check if docker compose project (folder) exists
    if [[ ! -d "$COMPOSE_DIR/$nombre" ]]; then
        echo "Error: No existe un directorio para el servidor '$nombre'."
        return 1
    fi

    # Use docker compose commands inside the server directory
    if [[ "$estado_actual" == "activo" ]]; then
        # Server is active, so bring it down (stop & remove containers)
        docker compose -f "$COMPOSE_DIR/$nombre/docker-compose.yml" down || {
            echo "Error: Falló docker compose down para $nombre"
            return 1
        }
        nuevo_estado="inactivo"
    else
        # Server is inactive, bring it up detached with build
        docker compose -f "$COMPOSE_DIR/$nombre/docker-compose.yml" up -d --build || {
            echo "Error: Falló docker compose up para $nombre"
            return 1
        }
        nuevo_estado="activo"
    fi

    red_asociada=$(grep "^$nombre," "$SERVIDORES_CSV" | cut -d',' -f2)
    sed -i "s/^$nombre,[^,]*,[^,]*/$nombre,$red_asociada,$nuevo_estado/" "$SERVIDORES_CSV"
    echo "Estado del servidor $nombre cambiado a $nuevo_estado."
}


reiniciar_servicio(){
    listar_servidores
    read -p "Nombre del servidor a reiniciar: " nombre
    reiniciar_contenedor $nombre
}

menu_servidores() {
    while true; do
        echo ""
        echo "==== Gestión de Servidores ===="
        echo "1. Listar servidores"
        echo "2. Crear servidor"
        echo "3. Eliminar servidor"
        echo "4. Activar/Desactivar servidor"
        echo "5. Reiniciar contenedor"
        echo "6. Iniciar contenedores inactivos"
        echo "9. Volver al menú principal"
        read -p "Seleccione una opción: " opcion

        case "$opcion" in
            1) listar_servidores ;;
            2) crear_servidor ;;
            3) eliminar_servidor ;;
            4) toggle_estado_servidor ;;
            5) reiniciar_servicio ;;
            6) correr_servidores_inactivos ;;
            9) break ;;
            *) echo "Opción no válida" ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    menu_servidores
fi
