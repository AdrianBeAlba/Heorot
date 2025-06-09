#!/bin/bash

# === Configuración ===
EXPORTS_DIR="exports"
COMPOSE_DIR="compose"
ROLES_DIR="roles"
UTILS_PATH="scripts/utils.sh"
TEMP_DIR="temp"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
CHECKPOINT_SUFFIX="checkpoint-export"

# === Cargar utilidades ===
if [[ ! -f "$UTILS_PATH" ]]; then
    echo "❌ No se encontró '$UTILS_PATH'."
    exit 1
fi
source "$UTILS_PATH"

# === Pedir nombre de exportación ===
read -p "Introduce el nombre del archivo de exportación (sin extensión): " EXPORT_NAME
EXPORT_NAME=${EXPORT_NAME:-"infraestructura_${TIMESTAMP}"}
EXPORT_PATH="${EXPORTS_DIR}/${EXPORT_NAME}.tar.gz"

# === Crear carpeta de exportaciones si no existe ===
mkdir -p "$EXPORTS_DIR"

# === Verificar estructura existente ===
for dir in "$COMPOSE_DIR" "$ROLES_DIR" "$TEMP_DIR"; do
    if [ ! -d "$dir" ]; then
        echo "❌ Falta la carpeta '$dir/'."
        exit 1
    fi
done

# === Crear checkpoints por contenedor ===
echo "🧠 Creando checkpoints de contenedores activos..."

while IFS=, read -r nombre_servidor _; do
    [[ "$nombre_servidor" == "nombre" || -z "$nombre_servidor" ]] && continue

    echo "⏳ Checkpointing contenedor: $nombre_servidor"

    checkpoint_path="${COMPOSE_DIR}/${nombre_servidor}/checkpoints"
    mkdir -p "$checkpoint_path"

    if ! docker checkpoint create --checkpoint-dir="$checkpoint_path" "$nombre_servidor" "$CHECKPOINT_SUFFIX"; then
        echo "❌ Error creando checkpoint para $nombre_servidor"
        exit 1
    fi
done < "$TEMP_DIR/servidores.csv"

# === Crear archivo tar.gz con toda la infraestructura ===
echo "📦 Empaquetando infraestructura (roles/, temp/, compose/)..."

tar -czf "$EXPORT_PATH" \
    "$ROLES_DIR"/ \
    "$TEMP_DIR"/ \
    "$COMPOSE_DIR/"

if [[ $? -ne 0 ]]; then
    echo "❌ Error durante la creación del archivo TAR."
    exit 1
fi

echo "✅ Exportación completada: $EXPORT_PATH"
