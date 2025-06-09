#!/bin/bash

# === Rutas base ===
EXPORTS_DIR="imports"
COMPOSE_DIR="compose"
UTILS_PATH="scripts/utils.sh"
IMPORT_TMP="tmp_import"

# === Cargar utilidades ===
if [[ ! -f "$UTILS_PATH" ]]; then
    echo "❌ No se encontró '$UTILS_PATH'. Aborta importación."
    exit 1
fi
source "$UTILS_PATH"

# === Mostrar lista de exportaciones disponibles ===
mapfile -t tar_files < <(find "$EXPORTS_DIR" -maxdepth 1 -type f -name "*.tar.gz")

if [[ ${#tar_files[@]} -eq 0 ]]; then
    echo "❌ No hay archivos .tar.gz en '$EXPORTS_DIR'."
    exit 1
fi

echo "📦 Elige el archivo de importación:"
select TAR_FILE in "${tar_files[@]}"; do
    [[ -n "$TAR_FILE" ]] && break
    echo "Selección inválida."
done

# === Confirmar backup previo ===
read -p "¿Hacer backup de la infraestructura actual antes de importar? (s/n): " confirm
if [[ "$confirm" =~ ^[sS]$ ]]; then
    ./scripts/export.sh || echo "⚠️ Backup previo fallido."
fi

# === Detener contenedores actuales ===
echo "⛔ Deteniendo contenedores existentes..."
for server_path in "$COMPOSE_DIR"/*/; do
    compose_file="${server_path}docker-compose.yml"
    if [[ -f "$compose_file" ]]; then
        docker compose -f "$compose_file" down
    fi
done

# === Prune de volúmenes y limpieza ===
echo "🧹 Pruneando volúmenes Docker y limpiando estructura anterior..."
docker volume prune -f
rm -rf "$COMPOSE_DIR" roles temp redes.csv

# === Descomprimir la importación ===
echo "📦 Extrayendo '$TAR_FILE'..."
mkdir -p "$IMPORT_TMP"
tar -xzf "$TAR_FILE" -C "$IMPORT_TMP"

# === Restaurar carpetas del entorno ===
mv "$IMPORT_TMP/compose" ./
mv "$IMPORT_TMP/roles" ./
mv "$IMPORT_TMP/temp" ./
mv "$IMPORT_TMP/redes.csv" ./ 2>/dev/null || true

# === Recrear redes ===
if [[ -f redes.csv ]]; then
    echo "🌐 Restaurando redes Docker..."
    while IFS=, read -r nombre red cidr; do
        [[ "$nombre" == "nombre" || -z "$nombre" ]] && continue
        echo "→ Creando red '$nombre' ($red/$cidr)..."
        docker network create --subnet="$red/$cidr" "$nombre" 2>/dev/null || true
    done < redes.csv
fi

# === Levantar contenedores ===
echo "🔼 Levantando contenedores desde nuevos 'compose'..."
for server_path in "$COMPOSE_DIR"/*/; do
    compose_file="${server_path}docker-compose.yml"
    if [[ -f "$compose_file" ]]; then
        docker compose -f "$compose_file" up -d
    fi
done

# === Copiar claves SSH ===
echo "🔐 Reinstalando claves SSH..."
if [[ -f temp/temp_servidores.csv ]]; then
    while IFS=, read -r nombre_servidor _; do
        [[ "$nombre_servidor" == "nombre" || -z "$nombre_servidor" ]] && continue
        copiar_clave_ssh "$nombre_servidor"
    done < temp/temp_servidores.csv
fi

# === Regenerar inventario de Ansible ===
echo "📜 Regenerando inventario Ansible..."
generar_inventario


# === Limpiar temporal ===
rm -rf "$IMPORT_TMP"

echo "✅ Importación completada con éxito. Infraestructura lista."
