import subprocess
from typing import Dict, Any, List

from rich.console import Console
from rich.progress import Progress

from simpleprod.tui.display import show_progress, show_error, show_warning
from simpleprod.i18n import get_message

console = Console()


def execute_steps(steps: List[str], config: Dict[str, Any], dry_run: bool) -> None:
    """Execute steps in order with error handling"""
    with Progress() as progress:
        task = progress.add_task("[cyan]Executing steps...", total=len(steps))

        for step in steps:
            if dry_run:
                console.print(f"[yellow]Dry-run: Would execute {step}[/yellow]")
                progress.update(task, advance=1)
                continue

            try:
                result = subprocess.run([f"./scripts/{step}.sh"], check=True, capture_output=True, text=True)
                console.print(f"[green]✓ {step} completed successfully[/green]")
                progress.update(task, advance=1)
            except subprocess.CalledProcessError as e:
                show_error(f"{step} failed: {e.stderr}")
                handle_failure(step, config)


def handle_failure(step: str, config: Dict[str, Any]) -> None:
    """Handle step failure with user options"""
    from questionary import select

    options = [
        get_message(config["lang"], "retry"),
        get_message(config["lang"], "skip"),
        get_message(config["lang"], "rollback"),
        get_message(config["lang"], "abort")
    ]

    choice = select(
        get_message(config["lang"], "failure_prompt").format(step=step),
        choices=options
    ).ask()

    if choice == get_message(config["lang"], "retry"):
        # Retry the same step
        pass
    elif choice == get_message(config["lang"], "skip"):
        # Skip to next step
        pass
    elif choice == get_message(config["lang"], "rollback"):
        # Execute rollback script
        subprocess.run(["./scripts/rollback.sh", step], check=True)
    else:
        # Abort execution
        raise SystemExit("Execution aborted by user")
