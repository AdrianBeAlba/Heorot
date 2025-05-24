#!/bin/bash

##############################################
# Gestor de Infraestructura con Docker y Ansible
# ----------------------------------------------
# Autor: Adrian Bejarano Albarracín
# Fecha: 26/03/2025
# Descripción: Script principal que gestiona el menú de opciones
#              y ejecuta los diferentes módulos del proyecto.
##############################################

# Función para gestionar servidores
gestionar_servicios() {
    clear
    bash scripts/servidores.sh
}

# Función para gestionar roles
gestionar_roles() {
    clear
    bash scripts/roles.sh
}

# Función para gestionar redes
gestionar_redes() {
    clear
    bash scripts/redes.sh
}

# Función para exportar la estructura actual
exportar_estructura() {
    bash scripts/export.sh
}

# Función para importar una estructura desde un ZIP
importar_estructura() {
    bash scripts/import.sh
}

# Función para realizar la configuración inicial
setup_inicial() {
    bash scripts/setup.sh
}

# Bucle principal del menú
while true; do
    echo "============================="
    echo "  HEOROT  "
    echo "============================="
    echo "0. Setup inicial"
    echo "1. Gestionar servidores"
    echo "2. Gestionar roles"
    echo "3. Gestionar redes"
    echo "4. Exportar estructura actual"
    echo "5. Importar estructura desde ZIP"
    echo "9. Salir"
    echo "============================="
    read -p "Seleccione una opción: " opcion

    case $opcion in
        0) setup_inicial ;;
        1) gestionar_servicios ;;
        2) gestionar_roles ;;
        3) gestionar_redes ;;
        4) exportar_estructura ;;
        5) importar_estructura ;;
        9) echo "Saliendo..."; exit 0 ;;
        *) echo "Opción no válida. Intente nuevamente."; sleep 2 ;;
    esac

done
