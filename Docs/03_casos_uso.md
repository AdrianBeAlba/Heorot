# Casos de Uso - Heorot

## Ejemplo 1: Laboratorio de Redes Virtuales
Un estudiante de redes necesita practicar configuración de servidores en distintas subredes.

- **Acciones**:
  - Crear varias redes virtuales (ej: Red_A 10.0.0.0/24, Red_B 10.0.1.0/24).
  - Crear servidores (servidor1, servidor2) asignados a diferentes redes.
  - Aplicar roles Ansible para instalar servicios como Apache o SSH.

## Ejemplo 2: Simulación de Entornos de Producción
Un administrador quiere probar despliegues antes de implementarlos en producción.

- **Acciones**:
  - Exportar la infraestructura real en un archivo ZIP.
  - Importarla en un entorno aislado.
  - Aplicar nuevas configuraciones o pruebas de migraciones.

## Ejemplo 3: Formación y Demostraciones
Un instructor quiere que sus alumnos experimenten levantando servidores configurados automáticamente.

- **Acciones**:
  - Prepara una infraestructura base.
  - La exporta y distribuye el ZIP.
  - Cada alumno importa el ZIP y trabaja sobre copias locales.

-----
# Ejemplos prácticos de flujo - Heorot

## Crear un nuevo servidor

1. Entra en la opción "Gestionar Servidores" → "Crear servidor".
2. Introduce:
   - Nombre: `webserver1`
   - Red: `default`
3. Heorot creará automáticamente el `compose/webserver1.yml` y lo registrará.

## Crear y asignar un rol

1. Entra en "Gestionar Roles" → "Crear rol".
2. Introduce:
   - Nombre del rol: `nginx`
3. Se genera la estructura del rol Ansible bajo `roles/nginx/`.
4. Para aplicarlo a un servidor:
   - Opción "Asignar rol".
   - Selecciona `webserver1` y el rol `nginx`.

## Crear una nueva red

1. En "Gestionar Redes" → "Crear red".
2. Introduce:
   - Nombre: `red_interna`
   - Subred: `10.10.0.0`
   - Máscara: `255.255.255.0`

Heorot creará la red Docker correspondiente y la añadirá a `redes.csv`.

---