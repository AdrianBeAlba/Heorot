#!/bin/bash

REDES_DIR="redes"
CSV_REDES="temp/redes.csv"

source scripts/utils.sh

mkdir -p "$REDES_DIR"
mkdir -p "$(dirname "$CSV_REDES")"

listar_redes() {
    echo "=== Redes Disponibles ==="
    if [[ ! -s "$CSV_REDES" ]]; then
        echo "No hay redes registradas."
        return
    fi

    awk -F, '{printf "- %s (%s / %s)\n", $1, $2, $3}' "$CSV_REDES"
}

crear_red() {
    read -p "Nombre de la nueva red: " nombre
    if grep -q "^$nombre," "$CSV_REDES"; then
        echo "Error: La red '$nombre' ya existe."
        return
    fi

    read -p "Dirección IP de la red (ej: 192.168.99.0): " direccion
    read -p "Máscara (ej: 255.255.255.0): " mascara

    cidr=$(mascara_a_cidr "$mascara")
    subnet="$direccion/$cidr"

    docker network create \
        --driver bridge \
        --subnet "$subnet" \
        "$nombre"

    if [[ $? -eq 0 ]]; then
        mkdir -p "$REDES_DIR/$nombre"
        echo "$nombre,$direccion,$mascara" >> "$CSV_REDES"
        echo "✅ Red '$nombre' creada correctamente con subred $subnet."
    else
        echo "❌ Error al crear la red."
    fi
}

eliminar_red() {
    listar_redes
    read -p "Nombre de la red a eliminar: " nombre

    if ! grep -q "^$nombre," "$CSV_REDES"; then
        echo "Error: La red '$nombre' no está registrada."
        return
    fi

    docker network rm "$nombre"
    if [[ $? -eq 0 ]]; then
        sed -i "/^$nombre,/d" "$CSV_REDES"
        rm -rf "$REDES_DIR/$nombre"
        echo "✅ Red '$nombre' eliminada correctamente."
    else
        echo "❌ No se pudo eliminar la red (quizá esté en uso)."
    fi
}

menu_redes() {
    while true; do
        echo "==== Gestión de Redes ===="
        echo "1. Listar redes"
        echo "2. Crear red"
        echo "3. Eliminar red"
        echo "9. Volver al menú principal"
        read -p "Seleccione una opción: " opcion

        case $opcion in
            1) listar_redes ;;
            2) crear_red ;;
            3) eliminar_red ;;
            9) return ;;
            *) echo "Opción no válida" ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    menu_redes
fi