#!/bin/bash

# === Colores ===
ROJO='\033[0;31m'
VERDE='\033[0;32m'
AMARILLO='\033[1;33m'
AZUL='\033[0;34m'
NC='\033[0m' # Sin color
#!/bin/bash

CSV="temp/servidores.csv"
INVENTARIO="temp/inventario.ini"
COMPOSE_DIR=compose
# === Funciones de redes ===
mascara_a_cidr() {
    IFS=. read -r i1 i2 i3 i4 <<< "$1"
    bin=$(printf '%08d%08d%08d%08d\n' \
        "$(bc <<< "obase=2;$i1")" \
        "$(bc <<< "obase=2;$i2")" \
        "$(bc <<< "obase=2;$i3")" \
        "$(bc <<< "obase=2;$i4")")
    echo "$bin" | grep -o "1" | wc -l
}

# === Funciones de inventario ansible ===
generar_inventario() {
    echo "[heorot]" > "$INVENTARIO"

    while IFS=',' read -r nombre red estado; do
        [[ "$estado" != "activo" ]] && continue

        puerto=$(docker port "$nombre" 22/tcp 2>/dev/null | awk -F: '{print $2}' | tr -d ' ')
        [[ -z "$puerto" ]] && continue

        echo "$nombre ansible_host=127.0.0.1 ansible_port=$puerto ansible_user=ansible" >> "$INVENTARIO"
    done < "$CSV"
}

crear_rolPorNombre() {
    local nombre_rol="$1"

    if [[ -z "$nombre_rol" ]]; then
        echo "Error: Debes proporcionar un nombre de rol."
        echo "Uso: crear_rol <nombre_rol>"
        return 1
    fi

    local rol_dir="roles/$nombre_rol"

    if [[ -d "$rol_dir" ]]; then
        echo "Error: El rol '$nombre_rol' ya existe."
        return 1
    fi

    # Crear estructura de carpetas
    mkdir -p "$rol_dir"/{tasks,handlers,defaults,vars,files,templates,meta}

    # Crear archivos base
    cat > "$rol_dir/tasks/main.yml" <<EOF
---
# Tareas principales para el rol $nombre_rol
EOF

    cat > "$rol_dir/handlers/main.yml" <<EOF
---
# Handlers para el rol $nombre_rol
EOF

    cat > "$rol_dir/defaults/main.yml" <<EOF
---
# Variables por defecto para el rol $nombre_rol
EOF

    cat > "$rol_dir/vars/main.yml" <<EOF
---
# Variables necesarias para el rol $nombre_rol
EOF

    cat > "$rol_dir/meta/main.yml" <<EOF
---
# Metadatos del rol $nombre_rol
dependencies: []
EOF

    cat > "$rol_dir/meta/volumes.yml" <<EOF
---
# volumes:
#  - path: /path/de/ejemplo
#    name: ejemplo
# Agrega aquí los volúmenes específicos que tu rol necesite
EOF

    cat > "$rol_dir/README.md" <<EOF
# Rol: $nombre_rol

Descripción del propósito del rol.
EOF

    # Registrar el rol en el CSV
    [[ ! -f temp/roles.csv ]] && touch temp/roles.csv
    echo "$nombre_rol" >> temp/roles.csv

    echo "Rol '$nombre_rol' creado correctamente con plantilla de volúmenes."
}



mapear_puerto_personalizado() {
    local servidor="$1"
    local compose_file="$COMPOSE_DIR/$servidor/docker-compose.yml"

    read -p "Puerto a exponer (dejar vacío para ninguno): " puerto_contenedor
    [[ -z "$puerto_contenedor" ]] && return 0

    read -p "Puerto de destino (puerto en el host): " puerto_host
    [[ -z "$puerto_host" ]] && {
        echo "⚠️  Debes especificar el puerto en el host."
        return 1
    }

    # Verificar si ya está mapeado
    if grep -q "\"${puerto_host}:${puerto_contenedor}\"" "$compose_file"; then
        echo "✅ El puerto ya está mapeado. No se hacen cambios."
        return 0
    fi

    echo "🛠️  Mapeando puerto: $puerto_host:$puerto_contenedor"

    # Insertar mapeo justo después del puerto 22 en docker-compose.yml
    sed -i "/- \"22\"/a \ \ \ \ \ \ - \"${puerto_host}:${puerto_contenedor}\"" "$compose_file"

    echo "✅ Puerto mapeado correctamente."
}

# === Funciones de contenedores ===
ansible_disponible(){
    local nombre=$1
    # Esperar hasta que el usuario 'ansible' exista dentro del contenedor
    echo "Esperando a que el usuario 'ansible' esté disponible..."
    for i in {1..100}; do
        if docker exec "$nombre" id ansible &>/dev/null; then
            echo "Usuario 'ansible' detectado."
            break
        fi
        sleep 1
    done
}

copiar_clave_ssh() {
    local nombre="$1"

    if [[ -z "$nombre" ]]; then
        echo "Error: Debes especificar el nombre del contenedor."
        return 1
    fi

    echo "⤷ Copiando clave SSH pública al contenedor '$nombre'..."

    # Asegúrate de que el contenedor está corriendo
    if ! docker ps --format '{{.Names}}' | grep -q "^${nombre}$"; then
        echo "Error: El contenedor '$nombre' no está en ejecución."
        return 1
    fi

    # Crear carpeta .ssh si no existe
    docker exec "$nombre" mkdir -p /home/ansible/.ssh

    # Copiar clave pública como authorized_keys
    docker cp ~/.ssh/id_rsa.pub "$nombre":/home/ansible/.ssh/authorized_keys

    # Ajustar permisos y propiedad
    docker exec "$nombre" chown -R ansible:ansible /home/ansible
    docker exec "$nombre" chmod 700 /home/ansible/.ssh
    docker exec "$nombre" chmod 600 /home/ansible/.ssh/authorized_keys

    echo "✅ Clave SSH copiada correctamente a '$nombre'."
}

reiniciar_contenedor(){
    local servidor="$1"
    local compose_file="$COMPOSE_DIR/$servidor/docker-compose.yml"
    echo "🔄 Reiniciando contenedor..."
    docker compose -f "$compose_file" down
    docker compose -f "$compose_file" up -d
    echo "Contenedor reiniciado."
}
