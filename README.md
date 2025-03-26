# Heorot
## **Documentación del Proyecto: Sistema de Gestión de Servidores con Docker, Ansible y Redes**

## **1. Introducción**
Este proyecto proporciona una solución automatizada para la gestión de servidores virtualizados utilizando **Docker**, la configuración de los mismos con **Ansible** y la gestión de redes. Se implementa a través de un **script principal en Bash**, el cual ofrece un **menú interactivo** con diversas opciones para facilitar su administración. Además, permite exportar e importar configuraciones completas en formato ZIP para su reutilización en otros entornos.

## **2. Funcionalidades del Menú Principal**

### **0. Setup (Instalación y Configuración Inicial)**
Esta opción configura el entorno para el correcto funcionamiento del sistema:
- Instala dependencias necesarias (**Docker, Docker Compose, Ansible, Python, SSH, Sudo**).
- Crea la estructura de carpetas y archivos iniciales.
- Genera una red predeterminada llamada `default`.
- Crea roles básicos de Ansible (`apache`, `dhcp`, `openldap`).
- Inicializa los CSV que almacenan la información de servidores, redes y roles.

---

### **1. Gestionar Servidores**
Permite gestionar los servidores Docker de la infraestructura.

**Submenú:**
- **Listar servidores**: Muestra los servidores creados.
- **Crear servidor**: Solicita nombre y red, generando su `docker-compose.yml`.
- **Renombrar servidor**: Permite modificar el nombre de un servidor.
- **Cambiar red del servidor**: Reasigna el servidor a una red diferente.
- **Eliminar servidor**: Borra su contenedor y archivo de configuración.

Los servidores se almacenan en `compose/` y se registran en `compose/servidores.csv`.

---

### **2. Gestionar Roles**
Permite gestionar los roles de Ansible y asignarlos a servidores.

**Submenú:**
- **Listar roles**: Muestra los roles disponibles.
- **Crear rol**: Genera una estructura de rol básica con `ansible-galaxy init`.
- **Asignar rol**: Aplica un rol a un servidor usando `ansible-playbook`.
- **Eliminar rol**: Borra la carpeta del rol y lo elimina del CSV.

Los roles se almacenan en `roles/` y se registran en `roles/roles.csv`.

---

### **3. Gestionar Redes**
Permite gestionar las redes Docker usadas por los servidores.

**Submenú:**
- **Listar redes**: Muestra las redes existentes.
- **Crear red**: Solicita un nombre y la crea con `docker network create`.
- **Renombrar red**: Modifica el nombre de una red.
- **Eliminar red**: Borra una red seleccionada.

Las redes se almacenan en `redes/` y se registran en `redes/redes.csv`.

---

### **4. Exportar Estructura Actual**
Guarda una copia de la infraestructura en un archivo ZIP dentro de `imports/`.

**Incluye:**
- Configuración de servidores (`compose/`).
- Configuración de roles (`roles/`).
- Configuración de redes (`redes/`).
- Archivos temporales en `temp/`.
- Opcionalmente, los datos de los servidores (`docker export`).

El usuario elige el nombre del archivo ZIP antes de exportarlo.

---

### **5. Importar Estructura desde ZIP**
Permite restaurar una infraestructura previamente exportada.

**Flujo:**
1. Muestra un listado de archivos ZIP disponibles en `imports/`.
2. Pregunta si se desea guardar la configuración actual antes de importar.
3. Borra la infraestructura actual.
4. Descomprime el ZIP seleccionado e implementa su contenido.
5. Si el ZIP contiene datos de servidores, los restaura con `docker import`.

---

## **3. Estructura de Directorios Final**

```
📂 Proyecto/
│
├── 📂 compose/              # Configuraciones de servidores Docker
│   ├── servidores.csv       # Listado de servidores
│
├── 📂 imports/              # Backups exportados
│   ├── infraestructura_backup_1.zip
│
├── 📂 roles/                # Roles de Ansible
│   ├── roles.csv            # Listado de roles disponibles
│
├── 📂 redes/                # Redes Docker
│   ├── redes.csv            # Listado de redes creadas
│
├── 📂 temp/                 # Archivos temporales generados durante la ejecución
│   ├── temp_servidores.csv
│   ├── temp_redes.csv
│   ├── temp_roles.csv
│
├── 📂 scripts/              # Scripts principales
│   ├── setup.sh             # Instalación y configuración inicial
│   ├── servidores.sh        # Gestión de servidores
│   ├── roles.sh             # Gestión de roles
│   ├── redes.sh             # Gestión de redes
│   ├── export.sh            # Exportación de infraestructura
│   ├── import.sh            # Importación de infraestructura
│
├── gestor.sh                # Script central del proyecto
└── docker-compose.yml        # Configuración global
```

## **4. Beneficios del Proyecto**

✔️ **Automatización Total**: Facilita la creación, configuración y gestión de servidores sin tareas manuales.
✔️ **Portabilidad**: Permite exportar e importar infraestructuras rápidamente.
✔️ **Eficiencia**: La carpeta `temp/` optimiza la gestión de datos temporales.
✔️ **Modularidad**: Se pueden agregar nuevos servidores, redes y roles sin modificar la estructura base.
✔️ **Compatibilidad**: Diseñado para funcionar en **Linux y WSL (Debian/Ubuntu)**.

---

📌 **Este documento proporciona una guía clara y estructurada del proyecto. ¿Necesitas alguna modificación o agregar algún detalle extra?** 🚀

