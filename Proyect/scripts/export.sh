#!/bin/bash

set -euo pipefail

COMPOSE_DIR="compose"
ROLES_DIR="roles"
TEMP_DIR="temp"

SERVIDORES="temp/servidores.csv"
EXPORT_TEMP="exports/temp_export"

source scripts/utils.sh

mkdir -p "$EXPORT_TEMP"

read -p "Nombre de la exportacion: " exp_name
ARCHIVE_NAME="exports/$exp_name.tar.gz"

while IFS=',' read -r nombre_servicio red estado; do
    # Saltar encabezado o líneas vacías
    [[ "$nombre_servicio" == "nombre" || -z "$nombre_servicio" ]] && continue
    dockerfile_path="compose/$nombre_servicio/Dockerfile"

    if [[ "$estado" == "activo" ]]; then
        echo "🔍 Procesando $nombre_servicio (estado: $estado)..."

        capturar_estado_contenedor "$nombre_servicio" "$dockerfile_path"|| {
            echo "❌ Falló la captura del contenedor $nombre_servicio"
            continue
        }

        imagen="${nombre_servicio}:latest"
        archivo_salida="$EXPORT_TEMP/${nombre_servicio// /_}.tar"

        echo "📦 Guardando imagen '$imagen' como '$archivo_salida'..."
        if docker save -o "$archivo_salida" "$imagen"; then
            echo "✅ Imagen exportada correctamente: $archivo_salida"
        else
            echo "❌ Error exportando la imagen: $imagen"
            continue
        fi
    else
        echo "⏭️  Saltando $nombre_servicio (estado: $estado)"
    fi
done < "$SERVIDORES"

# Comprobamos si los directorios existen
for DIR in "$COMPOSE_DIR" "$ROLES_DIR" "$TEMP_DIR" "$EXPORT_TEMP"; do
  if [ ! -d "$DIR" ]; then
    echo "Error: El directorio '$DIR' no existe." >&2
    exit 1
  fi
done

# Regenerar y actualizar inventario
generar_inventario

# Crear el archivo tar.gz
echo "Creando archivo $ARCHIVE_NAME con $COMPOSE_DIR, $EXPORT_TEMP, $ROLES_DIR y $TEMP_DIR..."
tar -czf "$ARCHIVE_NAME" "$COMPOSE_DIR" "$ROLES_DIR" "$TEMP_DIR" "$EXPORT_TEMP"

rm -rf "$EXPORT_TEMP"

echo "Archivo creado correctamente: $ARCHIVE_NAME"
