# **Documentación del Proyecto: Sistema de Gestión de Servidores con Docker, Ansible y Redes (Heorot)**

## **1. Introducción**
Este proyecto proporciona una solución automatizada para la gestión de servidores virtualizados utilizando **Docker**, la configuración de los mismos con **Ansible** y la gestión de redes. Se implementa a través de un **script principal en Bash**, el cual ofrece un **menú interactivo** con diversas opciones para facilitar su administración. Además, permite exportar e importar configuraciones completas en formato TAR para su reutilización en otros entornos.

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
- **Instala dependencias**: `docker.io`, `docker-compose`, `ansible`, `ssh`, `util-linux` y `bsdmainutils`.
- **Genera un rol de Apache en Ansible** utilizando `ansible-galaxy init`.
- Define las tareas necesarias en `tasks/main.yml` para instalar y configurar Apache.
- Crea un archivo `index.html` con el mensaje **"Bienvenido a Heorot!"** en la carpeta `files` del rol Apache.
---

### **1. Gestionar Servidores**
Permite gestionar los servidores Docker de la infraestructura.

**Submenú:**
- **Listar servidores**: Muestra los servidores creados.
- **Crear servidor**: Solicita nombre y red, generando su `docker-compose.yml`.
- **Eliminar servidor**: Borra su contenedor y archivo de configuración.
- **Activar/Desactivar servidor**: Activa o desactiva el contenedor de docker.

Los servidores se almacenan en `compose/` y se registran en `temp/servidores.csv`.

---

### **2. Gestionar Roles**
Permite gestionar los roles de Ansible y asignarlos a servidores.

**Submenú:**
- **Listar roles**: Muestra los roles disponibles.
- **Crear rol**: Genera una estructura de rol básica con `ansible-galaxy init`.
- **Asignar rol**: Aplica un rol a un servidor usando `ansible-playbook`.
- **Eliminar rol**: Borra la carpeta del rol y lo elimina del CSV.

Los roles se almacenan en `roles/` y se registran en `temp/roles.csv`.

---

### **3. Gestionar Redes**
Permite gestionar las redes Docker usadas por los servidores.

**Submenú:**
- **Listar redes**: Muestra las redes existentes.
- **Crear red**: Solicita un nombre y la crea con `docker network create`.
- **Eliminar red**: Borra una red seleccionada.

Las redes se almacenan en `redes/` y se registran en `temp/redes.csv`.

---

### **4. Exportar Estructura Actual**
Guarda una copia de la infraestructura en un archivo TAR dentro de `exports/`.

**Incluye:**
- Configuración de servidores (`compose/`).
- Contenido de los volumenes (`compose/<servidor>/volumes`).
- Configuración de roles (`roles/`).
- Configuración de redes (`temp/redes.csv`).
- Archivos temporales en `temp/`.
- Opcionalmente, los datos de los servidores (`docker export`).

El usuario elige el nombre del archivo TAR antes de exportarlo.

---

### **5. Importar Estructura desde TAR**
Permite restaurar una infraestructura previamente exportada.

**Flujo:**
1. Muestra un listado de archivos TAR disponibles en `imports/`.
2. Pregunta si se desea guardar la configuración actual antes de importar.
3. Borra la infraestructura actual.
4. Descomprime el TAR seleccionado e implementa su contenido.
5. Si el TAR contiene datos de servidores, los restaura con `docker import`.

---

## **4. Estructura de Directorios Final**

```
📂 Proyecto/
│
├── 📂 compose/              # Configuraciones de servidores Docker
│   ├── server
│   │   ├docker-compose.yml
│   │   ├volumes/
│
├── 📂 exports/              # Backups exportados
│   ├── infraestructura_backup_2.tar.gz
│
├── 📂 imports/              # Backups para importar
│   ├── infraestructura_backup_1.tar.gz
│
├── 📂 roles/                # Roles de Ansible
│
│
├── 📂 scripts/              # Scripts principales
│   ├── setup.sh             # Instalación y configuración inicial
│   ├── servidores.sh        # Gestión de servidores
│   ├── roles.sh             # Gestión de roles
│   ├── redes.sh             # Gestión de redes
│   ├── export.sh            # Exportación de infraestructura
│   ├── import.sh            # Importación de infraestructura
│
├── 📂 temp/                 # Archivos temporales generados durante la ejecución
│   ├── temp_servidores.csv
│   ├── temp_redes.csv
│   ├── temp_roles.csv
│   ├── inventario.ini        # Inventario de ansible, generado de manera dinamica
|
├── gestor.sh                # Script central del proyecto
```

## **5. Conclusión**
Este proyecto ofrece una solución integral para la gestión automatizada de servidores con Docker y Ansible. Su modularidad y facilidad de uso lo convierten en una herramienta potente para la administración de infraestructuras virtuales. Gracias a su capacidad de exportación e importación, permite la portabilidad de configuraciones, facilitando la replicación de entornos en diferentes sistemas.

## ⚠️ Advertencia: Problemas con WSL2 y bind volumes

Si ejecutas este proyecto en **WSL2** (por ejemplo, usando Docker Desktop en Windows), es posible que experimentes problemas al trabajar con volúmenes bind (`type: bind`). En particular:

### Problemas comunes:
- ❌ **No se eliminan correctamente las carpetas** que estaban montadas como volúmenes después de hacer `docker compose down`.
- ❌ `rm -rf` sobre carpetas en `compose/` puede fallar silenciosamente o dejar residuos inaccesibles.
- ❌ `setup` o recreación del servidor puede fallar por rutas que "parecen existir" pero están bloqueadas.
- 🔄 A veces es necesario reiniciar **WSL** o incluso **Docker Desktop** para poder continuar.

### Causa:
Esto ocurre por cómo WSL2 gestiona el sistema de archivos. Docker Desktop en Windows ejecuta los contenedores dentro de una máquina virtual, y las carpetas bind montadas desde el entorno WSL pueden quedar bloqueadas por el sistema debido a **sincronización diferida, cachés o locking de bajo nivel**.

### Soluciones recomendadas:
- ✅ Ejecuta el proyecto en un entorno **Ubuntu real** (ya sea instalado directamente o en una VM con soporte Docker).
- ✅ Si necesitas seguir usando WSL2:
  - El propio proyecto hace uso de `docker compose down && docker system prune -f` cuando se elimina un servidor.
  - Si eso falla, ejecuta:

    ```bash
    wsl --shutdown
    ```

    Y luego reinicia WSL y docker desktop antes de volver a intentar crear un servidor o la carpeta compose.
  - En el peor de los casos, tembien se recomienda reiniciar tu maquina en caso de que la solución anterior no solucione el problema.
---

> 💡 *Para evitar estos problemas completamente, se recomienda usar este proyecto desde un sistema Linux nativo.*


# Tambien ver

1. 📂 [Estructura del Proyecto](Docs/01_estructura_proyecto.md)
2. 🎯 [Filosofía y Objetivos](Docs/02_idea_fundamental.md)
3. 🛠️ [Casos de Uso](Docs/03_casos_uso.md)
4. 🧩 [Dependencias y Requisitos](Docs/04_dependencias.md)
5. 📦 [Documentacion avanzada](https://deepwiki.com/AdrianBeAlba/Heorot)
