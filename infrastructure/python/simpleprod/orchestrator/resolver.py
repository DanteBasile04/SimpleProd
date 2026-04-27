from typing import Dict, Any, List

from simpleprod.tui.display import show_progress


def resolve_steps(config: Dict[str, Any]) -> List[str]:
    """Resolve execution order based on config and dependencies"""
    execution_order = config["execution_order"]
    dependencies = config["dependencies"]
    path_requirements = config["path_requirements"].get(config["path"], [])
    selected_components = config["components"]

    # Filter steps based on path requirements and selected components
    steps = [step for step in execution_order
              if step in path_requirements and step in selected_components]

    # Verify all dependencies are met
    for step in steps:
        for dep in dependencies.get(step, []):
            if dep not in steps:
                raise ValueError(f"Missing dependency: {dep} for {step}")

    return steps
