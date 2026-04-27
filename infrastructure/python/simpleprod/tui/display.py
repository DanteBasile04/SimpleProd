from rich.console import Console
from rich.progress import Progress
from rich.panel import Panel
from rich.table import Table

console = Console()


def show_progress(total: int, description: str) -> Progress:
    """Show progress bar"""
    return Progress(
        "[progress.description]{task.description}",
        "[progress.percentage]{task.percentage:>3.0f}%",
        "[bar]{task.completed}/{task.total}",
        transient=True
    )


def show_error(message: str) -> None:
    """Show error message"""
    console.print(Panel(f"[red]{message}[/red]", title="Error", border_style="red"))


def show_warning(message: str) -> None:
    """Show warning message"""
    console.print(Panel(f"[yellow]{message}[/yellow]", title="Warning", border_style="yellow"))


def show_dry_run_preview(steps: list) -> None:
    """Show dry-run preview"""
    table = Table(title="Dry-run Preview")
    table.add_column("Step", style="cyan")
    table.add_column("Description", style="magenta")

    for step in steps:
        table.add_row(step, f"Would execute {step}")

    console.print(table)


def show_safety_summary(config: dict) -> None:
    """Show safety summary"""
    summary = Panel(
        f"[green]Path:[/green] {config['path']}\n"
        f"[green]User:[/green] {config['user']}\n"
        f"[green]SSH Port:[/green] {config['ssh_port']}\n"
        f"[yellow]Warning:[/yellow] Lockout risks if SSH port is non-standard",
        title="Safety Summary",
        border_style="green"
    )
    console.print(summary)
