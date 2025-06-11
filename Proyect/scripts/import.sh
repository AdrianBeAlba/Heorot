#!/bin/bash

IMPORT_DIR="imports"

source scripts/utils.sh
# Buscar archivos .tar.gz
mapfile -t ARCHIVOS < <(find "$IMPORT_DIR" -maxdepth 1 -name '*.tar.gz' | sort)

if [[ ${#ARCHIVOS[@]} -eq 0 ]]; then
    echo "❌ No se encontraron archivos .tar.gz en '$IMPORT_DIR'."
    exit 1
fi

echo "📦 Archivos de infraestructura disponibles:"
for i in "${!ARCHIVOS[@]}"; do
    echo "  [$i] ${ARCHIVOS[$i]}"
done

read -p "Selecciona un archivo por número: " seleccion

# Validar selección
if ! [[ "$seleccion" =~ ^[0-9]+$ ]] || (( seleccion < 0 || seleccion >= ${#ARCHIVOS[@]} )); then
    echo "❌ Selección inválida."
    exit 1
fi

ARCHIVO_ELEGIDO="${ARCHIVOS[$seleccion]}"
echo "✅ Has seleccionado: $ARCHIVO_ELEGIDO"
echo

# Ofrecer exportación de seguridad
read -p "¿Deseas hacer una copia de seguridad antes de continuar? (s/n): " hacer_backup
if [[ "$hacer_backup" =~ ^[sS]$ ]]; then
    echo "📤 Ejecutando backup con scripts/export.sh..."
    bash scripts/export.sh
    echo "✅ Backup finalizado."
    echo
fi

# Confirmar destrucción
echo "⚠️  Esta operación destruirá la infraestructura actual: contenedores, volúmenes, configuración..."
read -p "¿Estás seguro de continuar? (s/n): " confirmar
if [[ ! "$confirmar" =~ ^[sS]$ ]]; then
    echo "❌ Operación cancelada."
    exit 0
fi

echo "✅ Confirmación recibida. Continuando con la restauración..."

# Eliminar contenedores definidos en temp/servidores.csv
SERVIDORES_CSV="temp/servidores.csv"

if [[ -f "$SERVIDORES_CSV" ]]; then
    echo "🧹 Eliminando contenedores definidos en $SERVIDORES_CSV..."
    while IFS=',' read -r nombre_servicio red estado; do
        [[ "$nombre_servicio" == "nombre" || -z "$nombre_servicio" ]] && continue
        if docker ps -a --format '{{.Names}}' | grep -q "^$nombre_servicio$"; then
            echo "⛔ Parando y eliminando contenedor: $nombre_servicio"
            docker compose -f "compose/$nombre_servicio/docker-compose.yml" down || docker rm -f "$nombre_servicio"
        fi
    done < "$SERVIDORES_CSV"
else
    echo "⚠️  No se encontró $SERVIDORES_CSV, se omite eliminación de contenedores."
fi

# Eliminar directorios locales
echo "🗑️  Eliminando carpetas locales: compose/, roles/, temp/"
rm -rf compose roles temp

#Extraer los datos de la estructura
echo "📦 Extrayendo archivo: $ARCHIVO_ELEGIDO..."
tar -xzf "$ARCHIVO_ELEGIDO"

EXPORT_IMG_DIR="exports/temp_export"

if [[ -d "$EXPORT_IMG_DIR" ]]; then
    echo "📂 Cargando imágenes Docker desde $EXPORT_IMG_DIR..."
    for img_tar in "$EXPORT_IMG_DIR"/*.tar; do
        [[ -f "$img_tar" ]] || continue
        echo "📥 Cargando imagen: $img_tar"
        docker load -i "$img_tar"
    done
    echo "✅ Todas las imágenes han sido cargadas."

    # 🔥 Eliminar carpeta temporal de imágenes después de cargar
    echo "🧹 Limpiando carpeta temporal de imágenes..."
    rm -rf "$EXPORT_IMG_DIR"
else
    echo "⚠️  No se encontró la carpeta de imágenes: $EXPORT_IMG_DIR"
fi

#Importacion de redes
REDES_CSV="temp/redes.csv"

if [[ -f "$REDES_CSV" ]]; then
    echo "🌐 Creando redes definidas en $REDES_CSV..."
    while IFS=',' read -r nombre subnet mascara; do
        # Saltar encabezado o líneas vacías
        [[ "$nombre" == "nombre" || -z "$nombre" ]] && continue

        # Validar si ya existe la red
        if docker network ls --format '{{.Name}}' | grep -q "^${nombre}$"; then
            echo "🔁 Red '$nombre' ya existe, omitiendo creación."
        else
            echo "➕ Creando red '$nombre' con subred ${subnet}/${mascara}"
            docker network create \
                --driver bridge \
                --subnet "${subnet}/${mascara}" \
                "$nombre"
        fi
    done < "$REDES_CSV"
    echo "✅ Redes configuradas correctamente."
else
    echo "⚠️  No se encontró el archivo de redes: $REDES_CSV"
fi

#Levantar las maquinas
echo "Levantando maquinas"
correr_servidores_inactivos
