import yaml
from typing import Dict, Any

from simpleprod.tui.wizard import run_wizard

DEFAULT_CONFIG = {
    "path": "hybrid",
    "user": "simpleprod",
    "lang": "en",
    "components": [],
    "ssh_port": 22
}


def resolve_config(config_path: str, cli_path: str, cli_user: str, cli_lang: str) -> Dict[str, Any]:
    """Resolve configuration with priority: CLI > config file > defaults > wizard"""
    config = DEFAULT_CONFIG.copy()

    # Load config file if provided
    if config_path:
        with open(config_path, "r") as f:
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
    if not all(config.values()) and hasattr(sys, "stdin") and sys.stdin.isatty():
        config.update(run_wizard(config))

    if not all(config.values()):
        raise ValueError("Incomplete configuration and no TTY available for wizard")

    return config
