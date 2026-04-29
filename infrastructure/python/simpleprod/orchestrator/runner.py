import subprocess
import os
from pathlib import Path
from typing import Dict, Any, List

from rich.console import Console

from simpleprod.tui.display import show_error, show_warning

console = Console()

# Resolve the SimpleProd project root relative to this file
# runner.py -> orchestrator/ -> simpleprod/ -> python/ -> infrastructure/ -> project root
_PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent.parent.parent
_SCRIPTS_DIR = _PROJECT_ROOT / "infrastructure" / "bash" / "adapters"


def execute_steps(steps: List[str], config: Dict[str, Any], dry_run: bool) -> None:
    """Execute bash adapter scripts in dependency order with error handling.
    
    Scripts live in infrastructure/bash/adapters/{step}.sh
    """
    from rich.progress import Progress

    with Progress() as progress:
        task = progress.add_task("[cyan]Executing steps...", total=len(steps))

        for step in steps:
            if dry_run:
                console.print(f"[yellow]  [DRY RUN] {step}[/yellow]")
                progress.update(task, advance=1)
                continue

            script_path = _SCRIPTS_DIR / f"setup-{step}.sh"

            # Handle special case: nginx-ssl -> setup-nginx-ssl.sh
            # The bash adapter scripts use underscores: setup-{step}.sh
            if not script_path.exists():
                # Try with underscores instead of dashes
                alt_name = f"setup-{step.replace('-', '_')}.sh"
                script_path = _SCRIPTS_DIR / alt_name

            if not script_path.exists():
                console.print(f"[yellow]  SKIP: no script for {step} ({script_path.name})[/yellow]")
                progress.update(task, advance=1)
                continue

            try:
                result = subprocess.run(
                    ["bash", str(script_path)],
                    check=True,
                    capture_output=True,
                    text=True,
                    cwd=str(_PROJECT_ROOT),
                    env={**os.environ, "SP_LANG": config.get("lang", "en"),
                         "SP_USERNAME": config.get("user", "deploy"),
                         "SP_DRY_RUN": "true" if dry_run else "false"}
                )
                console.print(f"[green]  ✓ {step} completed[/green]")
                if result.stdout:
                    for line in result.stdout.strip().split("\n"):
                        console.print(f"    {line}")
                progress.update(task, advance=1)
            except subprocess.CalledProcessError as e:
                show_error(f"{step} failed: {e.stderr}")
                handle_failure(step, config)


def handle_failure(step: str, config: Dict[str, Any]) -> None:
    """Handle step failure with interactive user options"""
    from questionary import select
    from simpleprod.i18n import get_message

    lang = config.get("lang", "en")

    choice = select(
        get_message(lang, "failure_prompt").format(step=step),
        choices=[
            get_message(lang, "retry"),
            get_message(lang, "skip"),
            get_message(lang, "rollback"),
            get_message(lang, "abort")
        ]
    ).ask()

    if choice == get_message(lang, "retry"):
        execute_steps([step], config, dry_run=False)
    elif choice == get_message(lang, "skip"):
        console.print(f"[yellow]  Skipping {step}[/yellow]")
    elif choice == get_message(lang, "rollback"):
        rollback_script = _PROJECT_ROOT / "infrastructure" / "bash" / "common" / "backup.sh"
        if rollback_script.exists():
            subprocess.run(["bash", str(rollback_script), step], check=False)
        else:
            console.print("[red]No rollback script available[/red]")
    else:  # abort
        raise SystemExit("Execution aborted by user")