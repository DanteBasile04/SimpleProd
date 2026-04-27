import questionary
from typing import Dict, Any

from simpleprod.i18n import get_message


def run_wizard(config: Dict[str, Any]) -> Dict[str, Any]:
    """Run interactive configuration wizard"""
    config["lang"] = questionary.select(
        get_message(config["lang"], "language_prompt"),
        choices=[
            {"name": "English", "value": "en"},
            {"name": "Español", "value": "es"}
        ]
    ).ask()

    config["user"] = questionary.text(
        get_message(config["lang"], "username_prompt"),
        default=config["user"]
    ).ask()

    config["path"] = questionary.select(
        get_message(config["lang"], "path_prompt"),
        choices=[
            {"name": get_message(config["lang"], "docker_path"), "value": "docker"},
            {"name": get_message(config["lang"], "system_user_path"), "value": "system-user"},
            {"name": get_message(config["lang"], "hybrid_path"), "value": "hybrid"}
        ]
    ).ask()

    config["components"] = questionary.checkbox(
        get_message(config["lang"], "components_prompt"),
        choices=[
            {"name": "Base Tools", "value": "base-tools"},
            {"name": "User", "value": "user"},
            {"name": "SSH", "value": "ssh"},
            {"name": "UFW", "value": "ufw"},
            {"name": "Fail2Ban", "value": "fail2ban"},
            {"name": "Nginx SSL", "value": "nginx-ssl"},
            {"name": "Node.js", "value": "nodejs"},
            {"name": "Homebrew", "value": "homebrew"},
            {"name": "Zsh + Starship", "value": "zsh-starship"},
            {"name": "AI Tools", "value": "ai-tools"},
            {"name": "Docker", "value": "docker"},
            {"name": "PostgreSQL", "value": "postgresql"},
            {"name": "Backups", "value": "backups"},
            {"name": "Monitoring", "value": "monitoring"},
            {"name": "Logrotate", "value": "logrotate"}
        ],
        default=config["components"]
    ).ask()

    config["ssh_port"] = questionary.text(
        get_message(config["lang"], "ssh_port_prompt"),
        default=str(config["ssh_port"]),
        validate=lambda x: x.isdigit() and 1 <= int(x) <= 65535
    ).ask()

    return config
