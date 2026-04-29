import sys
import yaml
from typing import Dict, Any

from simpleprod.tui.wizard import run_wizard

DEFAULT_CONFIG = {
    "path": "hybrid",
    "user": "deploy",
    "lang": "en",
    "components": [
        "base-tools", "user", "ssh", "ufw", "fail2ban",
        "nginx-ssl", "nodejs", "docker", "postgresql",
        "backups", "monitoring", "logrotate"
    ],
    "ssh_port": 22,
    "execution_order": [
        "base-tools", "user", "ssh", "ufw", "fail2ban",
        "nginx-ssl", "nodejs", "homebrew", "zsh-starship", "ai-tools",
        "docker", "postgresql", "backups", "monitoring", "logrotate"
    ],
    "dependencies": {
        "base-tools": [],
        "user": ["base-tools"],
        "ssh": ["user"],
        "ufw": ["ssh"],
        "fail2ban": ["ssh", "ufw"],
        "nginx-ssl": ["ufw"],
        "nodejs": ["base-tools"],
        "homebrew": ["base-tools"],
        "zsh-starship": ["base-tools"],
        "ai-tools": ["base-tools"],
        "docker": ["base-tools"],
        "postgresql": ["base-tools"],
        "backups": ["postgresql"],
        "monitoring": ["base-tools"],
        "logrotate": ["nginx-ssl"]
    },
    "path_requirements": {
        "docker": ["base-tools", "user", "ssh", "ufw", "fail2ban", "nginx-ssl", "docker", "nodejs"],
        "system-user": ["base-tools", "user", "ssh", "ufw", "fail2ban", "nginx-ssl", "postgresql", "nodejs"],
        "hybrid": ["base-tools", "user", "ssh", "ufw", "fail2ban", "nginx-ssl", "docker", "postgresql", "nodejs"]
    }
}


def resolve_config(cli_config: str = None, cli_path: str = None,
                   cli_user: str = None, cli_lang: str = None) -> Dict[str, Any]:
    """Resolve configuration with priority: CLI > config file > defaults > wizard"""
    config = DEFAULT_CONFIG.copy()

    # Load config file if provided
    if cli_config:
        with open(cli_config, "r") as f:
            file_config = yaml.safe_load(f)
            if file_config:
                config.update(file_config)

    # Override with CLI arguments
    if cli_path:
        config["path"] = cli_path
    if cli_user:
        config["user"] = cli_user
    if cli_lang:
        config["lang"] = cli_lang

    # Run wizard if TTY available and config is incomplete
    required = ["path", "user"]
    if not all(config.get(k) for k in required):
        if not sys.stdin.isatty():
            raise ValueError("Incomplete configuration and no TTY available for wizard")
        config.update(run_wizard(config))

    return config