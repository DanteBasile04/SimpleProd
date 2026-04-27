import click
from simpleprod.orchestrator.config_resolver import resolve_config
from simpleprod.orchestrator.preflight import run_preflight_checks
from simpleprod.orchestrator.resolver import resolve_steps
from simpleprod.orchestrator.runner import execute_steps

@click.command()
@click.option("--config", type=click.Path(exists=True), help="Path to YAML config file")
@click.option("--path", type=click.Choice(["docker", "system-user", "hybrid"]), help="Execution path")
@click.option("--user", type=str, help="Username")
@click.option("--lang", type=click.Choice(["en", "es"]), default="en", help="Language")
@click.option("--dry-run", is_flag=True, help="Preview mode")
def main(config: str, path: str, user: str, lang: str, dry_run: bool):
    """Main CLI entry point"""
    config_data = resolve_config(config, path, user, lang)
    run_preflight_checks(config_data)
    steps = resolve_steps(config_data)
    execute_steps(steps, config_data, dry_run)
