#!/bin/bash

# === Colores ===
ROJO='\033[0;31m'
VERDE='\033[0;32m'
AMARILLO='\033[1;33m'
AZUL='\033[0;34m'
NC='\033[0m' # Sin color

# === Funciones de log ===
function log_info() {
    echo -e "${AZUL}[INFO]${NC} $1"
}

function log_ok() {
    echo -e "${VERDE}[OK]${NC} $1"
}

function log_error() {
    echo -e "${ROJO}[ERROR]${NC} $1"
}

function log_warn() {
    echo -e "${AMARILLO}[ADVERTENCIA]${NC} $1"
}

# === Función para pausar ===
function pausar() {
    read -p "Presione Enter para continuar..."
}

# === Confirmación sí/no ===
function confirmar() {
    read -p "$1 [s/N]: " confirm
    [[ "$confirm" == "s" || "$confirm" == "S" ]]
}

# === Comprobación de existencia de comando ===
function comando_existe() {
    command -v "$1" &> /dev/null
}
