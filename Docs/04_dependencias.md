
# Requisitos del sistema - Heorot

## Requisitos mínimos
- CPU: 2 núcleos
- RAM: 4 GB
- Almacenamiento: 10 GB libres
- Sistema operativo: Linux (Debian, Ubuntu o compatibles)
- Permisos de `sudo`
- Conexión a Internet para instalación de paquetes

## Requisitos recomendados
- CPU: 4 núcleos
- RAM: 8 GB o superior
- Almacenamiento: 20 GB libres o más
- Docker instalado y activo
- Docker Compose funcional
- Ansible instalado
- SSH configurado

# Dependencias del Proyecto - Heorot

## Software necesario

| Software         | Uso                             |
| ---------------- | ------------------------------- |
| Docker           | Motor de contenedores            |
| Docker Compose   | Orquestación de contenedores     |
| Ansible          | Automatización de configuraciones |
| zip / unzip      | Empaquetado y desempacado de backups |
| openssh-server   | Acceso SSH para ejecución de roles remotos |

## Instalación automática
Durante el `setup.sh`, se instala todo mediante:

~~~bash
sudo apt update && sudo apt install -y docker.io docker-compose ansible zip unzip ssh
~~~

***Nota: Si usas WSL2 en Windows, asegúrate de que Docker esté instalado y corriendo (Docker Desktop).***

## Recomendaciones
* Usar Ubuntu LTS o Debian 11/12 como base.

* Mantener Docker y Ansible actualizados para evitar incompatibilidades.