#!/usr/bin/env python3
"""Check Docker Compose files for consistent key ordering in services."""

import logging
import sys
from pathlib import Path
from typing import Any

import yaml

logging.basicConfig(
    level=logging.INFO,
    format="%(levelname)s: %(message)s",
)
logger = logging.getLogger(__name__)

KEY_ORDER = [
    "extends",
    "image",
    "build",
    "container_name",
    "hostname",
    "environment",
    "env_file",
    "networks",
    "network_mode",
    "ports",
    "expose",
    "volumes",
    "devices",
    "configs",
    "healthcheck",
    "labels",
    "restart",
    "depends_on",
    "mem_limit",
    "memswap_limit",
    "shm_size",
    "cap_add",
    "cap_drop",
    "security_opt",
    "privileged",
    "sysctls",
    "extra_hosts",
    "command",
    "entrypoint",
    "working_dir",
    "user",
    "group_add",
    "ulimits",
    "logging",
    "deploy",
    "profiles",
]


def get_key_index(key: str) -> int:
    """Get the expected index for a key. Unknown keys go at the end."""
    try:
        return KEY_ORDER.index(key)
    except ValueError:
        return len(KEY_ORDER)


def check_service_order(service_name: str, service_config: dict[str, Any]) -> list[str]:
    """Check if keys in a service are in the correct order."""
    errors: list[str] = []
    if not isinstance(service_config, dict):
        return errors

    keys = list(service_config.keys())
    expected_order = sorted(keys, key=get_key_index)

    for _i, (actual, expected) in enumerate(zip(keys, expected_order, strict=False)):
        if actual != expected:
            errors.append(
                f"Service '{service_name}': key '{actual}' should come after '{expected}'"
            )

    return errors


def check_file(filepath: Path) -> list[str]:
    """Check a single Docker Compose file."""
    errors: list[str] = []

    try:
        with open(filepath) as f:
            content: dict[str, Any] = yaml.safe_load(f)
    except yaml.YAMLError as e:
        return [f"YAML parsing error: {e}"]

    if not content or "services" not in content:
        return errors

    services = content["services"]
    if not isinstance(services, dict):
        return errors

    for service_name, service_config in services.items():
        service_errors = check_service_order(service_name, service_config)
        errors.extend(service_errors)

    return errors


def main() -> None:
    """Main entry point."""
    files = sys.argv[1:]
    if not files:
        logger.error("Usage: check_compose_order.py <file1> [file2] ...")
        sys.exit(1)

    all_errors: list[str] = []

    for filepath_str in files:
        filepath = Path(filepath_str)
        if not filepath.exists():
            all_errors.append(f"{filepath}: File not found")
            continue

        errors = check_file(filepath)
        if errors:
            all_errors.append(f"{filepath}:")
            all_errors.extend([f"  {e}" for e in errors])

    if all_errors:
        logger.error("Docker Compose key ordering errors found:")
        for error in all_errors:
            logger.error(error)
        logger.info("Expected key order: %s...", ", ".join(KEY_ORDER[:10]))
        logger.info("Tip: Reorder keys to match the expected order above.")
        sys.exit(1)
    else:
        logger.info("All Docker Compose files have correct key ordering.")
        sys.exit(0)


if __name__ == "__main__":
    main()
