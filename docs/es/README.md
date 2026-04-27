# SimpleProd

## Descripción del Proyecto
SimpleProd es una herramienta de aprovisionamiento de servidores que automatiza la configuración de servidores de producción con seguridad reforzada e isolación.

## Guía de Inicio Rápido

### Ruta de Isolación Docker
1. Instalar Docker
2. Ejecutar `docker-compose -f application/paths/docker/compose.yaml up`

### Ruta de Isolación de Usuario del Sistema
1. Instalar Ansible
2. Ejecutar `ansible-playbook -i infrastructure/ansible/inventory/production.yml infrastructure/ansible/playbooks/site.yml`

### Ruta Híbrida
1. Instalar Docker y Ansible
2. Ejecutar tanto el archivo compose de Docker como el playbook de Ansible

## Garantías de Seguridad
- Isolación de Dominio 0
- Prevención de bloqueo
- Verificaciones previas
- Manejo de fallos de pasos
- Copias de seguridad y rollback
- Gestión de secretos

## Opciones de Configuración
- Personalizar `application/paths/` para diferentes estrategias de isolación
- Modificar `infrastructure/ansible/inventory/` para configuraciones de múltiples servidores

## Cómo Funciona
SimpleProd sigue los principios de Clean Architecture con:
- Separación clara de preocupaciones
- Inversión de dependencias
- Despliegue independiente

## Contribuir
1. Hacer fork del repositorio
2. Crear una rama de características
3. Enviar una solicitud de extracción
