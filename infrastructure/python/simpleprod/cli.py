"""SimpleProd CLI — Click entry point"""
import click

from simpleprod.orchestrator.config_resolver import resolve_config
from simpleprod.orchestrator.preflight import run_preflight_checks
from simpleprod.orchestrator.resolver import resolve_steps
from simpleprod.orchestrator.runner import execute_steps
from simpleprod.tui.display import show_dry_run_preview, show_safety_summary


@click.command()
@click.option("--config", type=click.Path(exists=True), help="Path to YAML config file")
@click.option("--path", type=click.Choice(["docker", "system-user", "hybrid"]), help="Execution path")
@click.option("--user", type=str, help="Username for deploy user")
@click.option("--lang", type=click.Choice(["en", "es"]), default="en", help="Language for messages")
@click.option("--dry-run", is_flag=True, help="Preview mode — no changes made")
@click.option("--no-preflight", is_flag=True, help="Skip pre-flight checks (dangerous!)")
def main(config: str, path: str, user: str, lang: str, dry_run: bool, no_preflight: bool):
    """SimpleProd — VPS Production Setup Bundle

    Provision a fresh Ubuntu/Debian server for production.
    Safety-first with Domain 0 checks: backup, lockout prevention, rollback.
    """
    # Resolve configuration (CLI > config file > defaults > wizard)
    config_data = resolve_config(
        cli_config=config,
        cli_path=path,
        cli_user=user,
        cli_lang=lang
    )

    # Show safety summary
    show_safety_summary(config_data)

    # Run pre-flight checks (Domain 0)
    if not no_preflight:
        run_preflight_checks(config_data)

    # Resolve step execution order
    steps = resolve_steps(config_data)

    # Show dry-run preview if applicable
    if dry_run:
        show_dry_run_preview(steps)

    # Execute
    execute_steps(steps, config_data, dry_run)