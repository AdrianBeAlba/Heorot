# Estructura del Proyecto - Heorot

Heorot organiza su infraestructura de manera modular para asegurar facilidad de mantenimiento, escalabilidad y portabilidad.

## Directorios y Archivos

- **compose/**  
  Carpeta donde se guardan los `docker-compose.yml` de cada servidor individual.  
  También almacena `servidores.csv` para registrar la información básica de los contenedores.

- **roles/**  
  Contiene los roles de Ansible creados para configurar automáticamente los servidores.  
  Un archivo `roles.csv` lleva el control de los roles disponibles.

- **redes/**  
  Mantiene `redes.csv`, donde se listan las redes Docker personalizadas creadas para la infraestructura.

- **temp/**  
  Carpeta de archivos temporales generados durante la ejecución (ej: listados de servidores, redes y roles en uso).  
  Estos archivos permiten gestionar el estado interno de la plataforma sin afectar la persistencia de datos.

- **imports/**  
  Almacena los backups de toda la infraestructura comprimidos en archivos `.zip`.  
  Sirven para exportar el estado de un entorno y restaurarlo en cualquier momento.

- **scripts/**  
  Scripts Bash que contienen las funciones específicas del sistema: creación de servidores, redes, exportación/importación, etc.

- **gestor.sh**  
  Script principal que presenta el menú general interactivo.

- **docker-compose.yml**  
  Archivo global, si fuera necesario para levantar servicios comunes.

## Lógica de funcionamiento

La plataforma utiliza los CSV como **"bases de datos ligeras"**, donde cada operación en servidores, redes o roles actualiza automáticamente los listados correspondientes.  
Esto permite operaciones rápidas sin necesidad de bases de datos complejas.
