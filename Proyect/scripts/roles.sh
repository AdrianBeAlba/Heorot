#!/bin/bash

ROLES_DIR="roles"
ROLES_CSV="temp/roles.csv"
INVENTARIO="temp/inventario.ini"
SERVIDORES_CSV="temp/servidores.csv"
source scripts/utils.sh
source scripts/servidores.sh

function listar_roles() {
    echo "=== Roles Disponibles ==="
    if [[ ! -d "$ROLES_DIR" || -z $(ls -A "$ROLES_DIR") ]]; then
        echo "No hay roles creados."
        return
    fi

    for rol in "$ROLES_DIR"/*; do
        [ -d "$rol" ] && echo "- $(basename "$rol")"
    done
}

function crear_rol() {
    read -p "Nombre del rol: " nombre
    crear_rolPorNombre $nombre
}

function asignar_rol() {
    listar_roles
    read -p "Nombre del rol a asignar: " rol

    if [[ ! -d "$ROLES_DIR/$rol" ]]; then
        echo "El rol '$rol' no existe."
        return
    fi

    listar_servidores
    read -p "Servidor destino: " servidor

    if ! grep -q "^$servidor," "$SERVIDORES_CSV"; then
        echo "El servidor '$servidor' no está registrado."
        return
    fi

    mapear_puerto_personalizado "$servidor"

    # === Leer volumes.yml y preparar volúmenes ===
    volumes_file="$ROLES_DIR/$rol/meta/volumes.yml"
    server_vol_dir="volumes"
    volumes_lines=""

    if [[ -f "$volumes_file" ]]; then
        echo "Configurando volúmenes del rol..."
        container_path=""
        host_rel_path=""
        while IFS= read -r line; do
            if [[ "$line" =~ container_path:\ (.+) ]]; then
                container_path="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ host_path:\ (.+) ]]; then
                host_rel_path="${BASH_REMATCH[1]}"
            fi

            if [[ -n "$container_path" && -n "$host_rel_path" ]]; then
                host_path="${server_vol_dir%/}/${host_rel_path#/}"
                volumes_lines+="      - type: bind"$'\n'
                volumes_lines+="        source: ./${host_path}"$'\n'
                volumes_lines+="        target: ${container_path}"$'\n'
                container_path=""
                host_rel_path=""
            fi
        done < "$volumes_file"
    fi
    echo "$volumes_lines"

    compose_file="compose/$servidor/docker-compose.yml"

    # Si ya existe la sección volumes, la reemplazamos; si no, la insertamos antes de tty:
    if grep -q "^[[:space:]]*volumes:" "$compose_file"; then
        # Reemplazamos toda la sección volumes (línea volumes + líneas indentadas debajo)
        awk -v vols="$volumes_lines" '
        BEGIN {in_vol=0}
        /^[[:space:]]*volumes:/ {
            print "    volumes:"
            printf "%s", vols
            in_vol=1
            next
        }
        in_vol && /^[[:space:]]*[^ ]/ { in_vol=0 }
        !in_vol { print }
        ' "$compose_file" > "${compose_file}.tmp" && mv "${compose_file}.tmp" "$compose_file"
    else
        # Insertamos sección de volumes antes de la línea tty:
        tmp_vol_file=$(mktemp)
        echo "    volumes:" > "$tmp_vol_file"
        printf "%s" "$volumes_lines" >> "$tmp_vol_file"

        awk -v insert="$(cat "$tmp_vol_file")" '
        BEGIN { inserted=0 }
        /^[[:space:]]*tty:/ && !inserted {
            print insert
            inserted=1
        }
        { print }
        ' "$compose_file" > "${compose_file}.tmp" && mv "${compose_file}.tmp" "$compose_file"
        rm -f "$tmp_vol_file"
    fi

    # Reiniciar contenedor para aplicar volúmenes
    reiniciar_contenedor "$servidor"
    # Regenerar inventario
    generar_inventario "$servidor" > "$INVENTARIO"

    # Playbook temporal
    playbook_temp="roles/apply_${rol}_to_${servidor}.yml"
    cat > "$playbook_temp" <<EOF
- hosts: $servidor
  become: true
  roles:
    - $rol
EOF

    # Asegurar conexión SSH y aplicar rol
    ansible_disponible "$servidor"
    copiar_clave_ssh "$servidor"
    ansible-playbook -i "$INVENTARIO" "$playbook_temp"
    rm -f $playbook_temp

    echo "Rol '$rol' asignado a '$servidor'."
}



function eliminar_rol() {
    read -p "Nombre del rol a eliminar: " rol

    if [[ ! -d "$ROLES_DIR/$rol" ]]; then
        echo "El rol '$rol' no existe."
        return
    fi

    rm -rf "$ROLES_DIR/$rol"
    grep -v "^$rol," "$ROLES_CSV" > "$ROLES_CSV.tmp" && mv "$ROLES_CSV.tmp" "$ROLES_CSV"
    echo "Rol '$rol' eliminado y registros actualizados."
}

function menu_roles() {
    while true; do
        echo "==== Gestión de Roles ===="
        echo "1. Listar roles"
        echo "2. Crear rol"
        echo "3. Asignar rol"
        echo "4. Eliminar rol"
        echo "9. Volver al menú principal"
        read -p "Seleccione una opción: " opcion

        case $opcion in
            1) listar_roles ;;
            2) crear_rol ;;
            3) asignar_rol ;;
            4) eliminar_rol ;;
            9) break ;;
            *) echo "Opción inválida" ;;
        esac
    done
}

menu_roles
