import questionary
from rich.console import Console
from rich.panel import Panel

from simpleprod.i18n import get_message

console = Console()


def show_path_menu(lang: str) -> str:
    """Show path selection menu with descriptions"""
    choices = [
        {
            "name": get_message(lang, "docker_path"),
            "value": "docker",
            "description": get_message(lang, "docker_path_desc")
        },
        {
            "name": get_message(lang, "system_user_path"),
            "value": "system-user",
            "description": get_message(lang, "system_user_path_desc")
        },
        {
            "name": get_message(lang, "hybrid_path"),
            "value": "hybrid",
            "description": get_message(lang, "hybrid_path_desc")
        }
    ]

    for choice in choices:
        console.print(Panel(choice["description"], title=choice["name"]))

    return questionary.select(
        get_message(lang, "path_prompt"),
        choices=choices
    ).ask()
