import sys
import os
import subprocess
from typing import Dict, Any

from rich.console import Console
from rich.panel import Panel

console = Console()


def check_root() -> bool:
    """Check if running as root"""
    try:
        return os.geteuid() == 0
    except AttributeError:
        return False


def check_os() -> bool:
    """Check supported OS"""
    try:
        with open("/etc/os-release", "r") as f:
            content = f.read()
            return "ubuntu" in content.lower() or "debian" in content.lower()
    except FileNotFoundError:
        return False


def check_internet() -> bool:
    """Check internet connectivity"""
    try:
        subprocess.run(["ping", "-c", "1", "8.8.8.8"], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return True
    except subprocess.CalledProcessError:
        return False


def check_disk_space(min_gb: int = 10) -> bool:
    """Check available disk space"""
    stat = os.statvfs("/")
    free_gb = (stat.f_bavail * stat.f_frsize) / (1024 ** 3)
    return free_gb >= min_gb


def check_ram(min_gb: int = 1) -> bool:
    """Check available RAM"""
    with open("/proc/meminfo", "r") as f:
        for line in f:
            if line.startswith("MemAvailable:"):
                available_kb = int(line.split()[1])
                available_gb = available_kb / (1024 ** 2)
                return available_gb >= min_gb
    return False


def run_preflight_checks(config: Dict[str, Any]) -> None:
    """Run all pre-flight checks"""
    checks = [
        (check_root(), "Root privileges"),
        (check_os(), "Supported OS"),
        (check_internet(), "Internet connectivity"),
        (check_disk_space(), "Disk space"),
        (check_ram(), "RAM")
    ]

    all_passed = True
    for passed, name in checks:
        if not passed:
            all_passed = False
            console.print(Panel(f"[red]✗ {name} check failed[/red]", title="Pre-flight Check"))
        else:
            console.print(Panel(f"[green]✓ {name} check passed[/green]", title="Pre-flight Check"))

    if not all_passed:
        raise SystemExit("Pre-flight checks failed")
