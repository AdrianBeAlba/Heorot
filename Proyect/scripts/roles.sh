#!/bin/bash

ROLES_DIR="roles"
ROLES_CSV="temp/roles.csv"
INVENTARIO="temp/inventario.ini"
SERVIDORES_CSV="temp/servidores.csv"
source scripts/utils.sh
source scripts/servidores.sh

listar_roles() {
    echo "=== Roles Disponibles ==="
    
    if [[ ! -f "$ROLES_CSV" || ! -s "$ROLES_CSV" ]]; then
        echo "No hay roles registrados."
        return
    fi

    cut -d',' -f1 "$ROLES_CSV" | while read -r rol; do
        [[ -n "$rol" ]] && echo "- $rol"
    done
}

crear_rol() {
    read -p "Nombre del rol: " nombre
    crear_rolPorNombre $nombre
}

asignar_rol() {
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

    if grep -q "^[[:space:]]*volumes:" "$compose_file"; then
    # Extract existing volumes block lines
    vol_indent=$(awk '/^[[:space:]]*volumes:/ {match($0, /^[[:space:]]*/); print RLENGTH; exit}' "$compose_file")
    # Extract volumes block (lines starting at volumes: and indented more)
    existing_volumes=$(awk -v indent="$vol_indent" '
        BEGIN { in_vol=0 }
        /^[[:space:]]*volumes:/ { in_vol=1; print; next }
        {
          match($0, /^[[:space:]]*/)
          line_indent = RLENGTH
          if (in_vol && line_indent > indent) {
            print
          } else if (in_vol && line_indent <= indent) {
            exit
          }
        }
    ' "$compose_file")

    # Normalize existing volumes to just source-target lines for comparison
    existing_pairs=$(echo "$existing_volumes" | awk '
      /source:/ { src=$2 }
      /target:/ { tgt=$2; print src "->" tgt }
    ')

    # Normalize new volumes (volumes_lines) similarly
    new_pairs=$(echo "$volumes_lines" | awk '
      /source:/ { src=$2 }
      /target:/ { tgt=$2; print src "->" tgt }
    ')

    # Merge unique volume pairs
    merged_pairs=$(echo -e "$existing_pairs\n$new_pairs" | sort -u)

    # Rebuild merged volumes block with indentation (4 spaces)
    merged_volumes="    volumes:\n"
    while IFS= read -r pair; do
      src=$(echo "$pair" | cut -d'-' -f1)
      tgt=$(echo "$pair" | cut -d'>' -f2)
      merged_volumes+="      - type: bind\n"
      merged_volumes+="        source: $src\n"
      merged_volumes+="        target: $tgt\n"
    done <<< "$merged_pairs"

    # Replace old volumes block with merged_volumes in compose_file
    awk -v indent="$vol_indent" -v merged="$merged_volumes" '
    BEGIN { in_vol=0 }
    /^[[:space:]]*volumes:/ {
      print merged
      in_vol=1
      next
    }
    {
      match($0, /^[[:space:]]*/)
      line_indent = RLENGTH
      if (in_vol && line_indent > indent) {
        next
      } else if (in_vol && line_indent <= indent) {
        in_vol=0
      }
      print
    }
    ' "$compose_file" > "${compose_file}.tmp" && mv "${compose_file}.tmp" "$compose_file"

    else
        # Insert volumes section before first tty: line (as before)
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
    generar_inventario

    # Playbook temporal
    playbook_temp="roles/apply_${rol}_to_${servidor}.yml"
    cat > "$playbook_temp" <<EOF
- hosts: $servidor
  become: true
  roles:
    - $rol
EOF

    server_conf_file="compose/$servidor/supervisord.conf"
    rol_conf_file="$ROLES_DIR/$rol/meta/services.conf"
    inyectar_supervisord_conf $server_conf_file $rol_conf_file


    # Asegurar conexión SSH y aplicar rol
    ansible_disponible "$servidor"
    copiar_clave_ssh "$servidor"
    sleep 3
    ansible-playbook -i "$INVENTARIO" "$playbook_temp"
    rm -f $playbook_temp

    # Aplicar permanencia
    server_dockerfile="compose/$servidor/dockerfile"
    capturar_estado_contenedor "$servidor" "$server_dockerfile"
    reiniciar_contenedor "$servidor"

    echo "Rol '$rol' asignado a '$servidor'."
}

eliminar_rol() {
    listar_roles
    read -p "Nombre del rol a eliminar: " rol

    if [[ -z $(cat $ROLES_CSV | grep $rol) ]]; then
        echo "El rol '$rol' no existe."
        return
    fi

    rm -rf "$ROLES_DIR/$rol"
    sed -i "/^$rol/d" "$ROLES_CSV"
    echo "Rol '$rol' eliminado y registros actualizados."
}

menu_roles() {
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
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    menu_roles
fi