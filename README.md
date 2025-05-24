# **Documentación del Proyecto: Sistema de Gestión de Servidores con Docker, Ansible y Redes (Heorot)**

## **1. Introducción**
Este proyecto proporciona una solución automatizada para la gestión de servidores virtualizados utilizando **Docker**, la configuración de los mismos con **Ansible** y la gestión de redes. Se implementa a través de un **script principal en Bash**, el cual ofrece un **menú interactivo** con diversas opciones para facilitar su administración. Además, permite exportar e importar configuraciones completas en formato ZIP para su reutilización en otros entornos.

## **2. Resumen del Proyecto**
El sistema proporciona una interfaz en Bash para gestionar servidores en contenedores Docker, configurar servicios con Ansible y administrar redes de forma automatizada. 

**Funcionalidades clave:**
- **Instalación y configuración automática**: Un setup inicial que instala dependencias y configura el entorno.
- **Gestor de servidores**: Creación, eliminación, renombrado y reasignación de servidores Docker con `docker-compose`.
- **Gestor de roles Ansible**: Creación y asignación de roles para configurar servidores automáticamente.
- **Gestor de redes**: Creación, eliminación y administración de redes Docker.
- **Exportación e importación de infraestructura**: Guarda y restaura configuraciones completas, incluyendo datos de los contenedores.

**Beneficios:**
- **Automatización Total**: Facilita la creación, configuración y gestión de servidores sin tareas manuales.
- **Portabilidad**: Permite exportar e importar infraestructuras rápidamente.
- **Eficiencia**: La carpeta `temp/` optimiza la gestión de datos temporales.
- **Modularidad**: Se pueden agregar nuevos servidores, redes y roles sin modificar la estructura base.
- **Compatibilidad**: Diseñado para funcionar en **Linux y WSL (Debian/Ubuntu)**.

## **3. Funcionalidades del Menú Principal**

### 0. Setup (Instalación y configuración inicial)
- Crea la estructura de carpetas necesarias: `compose`, `roles`, `redes`, `temp`, `imports`, `scripts`.
- Genera los archivos CSV base (`redes.csv`, `servidores.csv`, `roles.csv`).
- Crea la red **default** (192.168.99.0/24).
- **Instala dependencias**: `docker.io`, `docker-compose`, `ansible`, `zip`, `unzip`, `ssh`, `util-linux` y `bsdmainutils`.
- **Genera un rol de Apache en Ansible** utilizando `ansible-galaxy init`.
- Define las tareas necesarias en `tasks/main.yml` para instalar y configurar Apache.
- Crea un archivo `index.html` con el mensaje **"Bienvenido a Heorot!"** en la carpeta `files` del rol Apache.
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

## **4. Estructura de Directorios Final**

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

## **5. Conclusión**
Este proyecto ofrece una solución integral para la gestión automatizada de servidores con Docker y Ansible. Su modularidad y facilidad de uso lo convierten en una herramienta potente para la administración de infraestructuras virtuales. Gracias a su capacidad de exportación e importación, permite la portabilidad de configuraciones, facilitando la replicación de entornos en diferentes sistemas.

# Tambien ver

1. 📂 [Estructura del Proyecto](Docs/01_estructura_proyecto.md)
2. 🎯 [Filosofía y Objetivos](Docs/02_idea_fundamental.md)
3. 🛠️ [Casos de Uso](Docs/03_casos_uso.md)
4. 🧩 [Dependencias y Requisitos](Docs/04_dependencias.md)
