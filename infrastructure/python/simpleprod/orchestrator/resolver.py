from typing import Dict, Any, List


def resolve_steps(config: Dict[str, Any]) -> List[str]:
    """Resolve execution order based on config and dependencies.
    
    Filters the execution_order based on selected components and 
    path_requirements, then verifies all dependencies are satisfied.
    """
    execution_order = config.get("execution_order", [])
    dependencies = config.get("dependencies", {})
    path_reqs = config.get("path_requirements", {}).get(config.get("path", ""), [])
    selected = config.get("components", [])

    # Filter steps by both path requirements AND selected components
    steps = [step for step in execution_order
             if step in path_reqs and step in selected]

    # Verify all dependencies are met
    missing = set()

    for step in steps:
        for dep in dependencies.get(step, []):
            if dep not in steps:
                missing.add(dep)

    if missing:
        raise ValueError(f"Missing dependencies for selected steps: {', '.join(missing)}")

    return steps