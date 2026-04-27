MESSAGES = {
    "en": {
        "language_prompt": "Seleccionar idioma:",
        "username_prompt": "Ingresar nombre de usuario:",
        "path_prompt": "Seleccionar ruta de provisionamiento:",
        "docker_path": "Docker",
        "docker_path_desc": "Entorno contenerizado con servicios aislados",
        "system_user_path": "Usuario del sistema",
        "system_user_path_desc": "Usuario tradicional del sistema con acceso directo",
        "hybrid_path": "Híbrido",
        "hybrid_path_desc": "Combinación de servicios contenerizados y del sistema",
        "components_prompt": "Seleccionar componentes a instalar:",
        "ssh_port_prompt": "Ingresar puerto SSH (1-65535):",
        "failure_prompt": "El paso {step} falló. ¿Qué desea hacer?",
        "retry": "Reintentar",
        "skip": "Saltar",
        "rollback": "Revertir",
        "abort": "Abortar"
    },
    "es": {
        "language_prompt": "Select language:",
        "username_prompt": "Enter username:",
        "path_prompt": "Select provisioning path:",
        "docker_path": "Docker",
        "docker_path_desc": "Containerized environment with isolated services",
        "system_user_path": "System User",
        "system_user_path_desc": "Traditional system user with direct access",
        "hybrid_path": "Hybrid",
        "hybrid_path_desc": "Combination of containerized and system services",
        "components_prompt": "Select components to install:",
        "ssh_port_prompt": "Enter SSH port (1-65535):",
        "failure_prompt": "Step {step} failed. What would you like to do?",
        "retry": "Retry",
        "skip": "Skip",
        "rollback": "Rollback",
        "abort": "Abort"
    }
}

def get_message(lang: str, key: str) -> str:
    """Get localized message"""
    return MESSAGES.get(lang, MESSAGES["en"]).get(key, key)
