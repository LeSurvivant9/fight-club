#!/usr/bin/env python3
"""Comprehensive validation of all Docker Compose files."""

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

EXPECTED_ROOT_ORDER = ["services", "networks", "configs", "volumes", "secrets"]
EXPECTED_SERVICE_ORDER = [
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

INFRASTRUCTURE_NETWORKS = {"proxy", "media_int", "vpn_net", "socket_proxy"}


def check_root_keys_order(content: dict[str, Any]) -> list[str]:
    """Check if root keys are in correct order with services first."""
    errors: list[str] = []
    root_keys = list(content.keys())

    def get_root_index(key: str) -> int:
        try:
            return EXPECTED_ROOT_ORDER.index(key)
        except ValueError:
            return len(EXPECTED_ROOT_ORDER)

    expected_order = sorted(root_keys, key=get_root_index)

    if root_keys != expected_order:
        errors.append(f"Root keys order incorrect: {root_keys} should be {expected_order}")

    if root_keys[0] != "services":
        errors.append(f"First root key should be 'services', got '{root_keys[0]}'")

    return errors


def check_service_keys_order(service_name: str, service_config: dict[str, Any]) -> list[str]:
    """Check if service keys are in correct order."""
    errors: list[str] = []
    if not isinstance(service_config, dict):
        return errors

    keys = list(service_config.keys())

    def get_key_index(key: str) -> int:
        try:
            return EXPECTED_SERVICE_ORDER.index(key)
        except ValueError:
            return len(EXPECTED_SERVICE_ORDER)

    expected_order = sorted(keys, key=get_key_index)

    for actual, expected in zip(keys, expected_order, strict=False):
        if actual != expected:
            errors.append(
                f"Service '{service_name}': key '{actual}' should come after '{expected}'"
            )
            break

    return errors


def get_networks_used_by_services(content: dict[str, Any]) -> set[str]:
    """Extract all network names used by services in the compose file."""
    networks_used: set[str] = set()
    services = content.get("services", {})

    if isinstance(services, dict):
        for service_config in services.values():
            if isinstance(service_config, dict):
                service_networks = service_config.get("networks", {})
                if isinstance(service_networks, list):
                    networks_used.update(service_networks)
                elif isinstance(service_networks, dict):
                    networks_used.update(service_networks.keys())

    return networks_used


def check_networks_usage(content: dict[str, Any], filepath: Path) -> list[str]:
    """Check networks usage - infrastructure networks must be defined as external."""
    errors: list[str] = []

    # Skip infrastructure file - it's supposed to define networks
    is_infrastructure = "infrastructure" in str(filepath)

    if is_infrastructure:
        return errors

    networks_used = get_networks_used_by_services(content)
    infrastructure_networks_used = networks_used.intersection(INFRASTRUCTURE_NETWORKS)

    # Check that infrastructure networks are properly defined as external
    root_networks = content.get("networks", {})
    if not isinstance(root_networks, dict):
        root_networks = {}

    for net_name in infrastructure_networks_used:
        if net_name not in root_networks:
            errors.append(
                f"Network '{net_name}' is used by services but not defined at root level "
                f"(must be defined with external: true)"
            )
        elif not root_networks[net_name] or root_networks[net_name].get("external") is not True:
            errors.append(
                f"Network '{net_name}' must be defined with external: true "
                f"(managed by infrastructure stack)"
            )

    # Check for unknown networks in services
    if "services" in content and isinstance(content["services"], dict):
        for service_name, service_config in content["services"].items():
            if isinstance(service_config, dict) and "networks" in service_config:
                service_networks = service_config["networks"]
                if isinstance(service_networks, dict):
                    for net_name in service_networks:
                        if net_name not in INFRASTRUCTURE_NETWORKS and net_name != "default":
                            errors.append(
                                f"Service '{service_name}' uses unknown network '{net_name}'"
                            )

    return errors


def check_extends_usage(content: dict[str, Any], filepath: Path) -> tuple[list[str], list[str]]:
    """Check if services use extends from common.yml."""
    errors: list[str] = []
    warnings: list[str] = []

    if filepath.name == "infrastructure/docker-compose.yml" or "infrastructure" in str(filepath):
        return errors, warnings

    if "services" in content and isinstance(content["services"], dict):
        for service_name, service_config in content["services"].items():
            if isinstance(service_config, dict):
                if "extends" not in service_config:
                    warnings.append(
                        f"Service '{service_name}' does not use extends (optional but recommended)"
                    )
                elif isinstance(service_config["extends"], dict):
                    extends = service_config["extends"]
                    if extends.get("file") != "../common.yml":
                        file_val = extends.get("file")
                        errors.append(f"Service '{service_name}' extends wrong file: {file_val}")
                    if extends.get("service") != "common-config":
                        svc_val = extends.get("service")
                        errors.append(f"Service '{service_name}' extends wrong service: {svc_val}")

    return errors, warnings


def validate_file(filepath: Path) -> tuple[list[str], list[str]]:
    """Validate a single Docker Compose file. Returns (errors, warnings)."""
    errors: list[str] = []
    warnings: list[str] = []

    try:
        with open(filepath) as f:
            content: dict[str, Any] = yaml.safe_load(f)
    except yaml.YAMLError as e:
        return [f"YAML parsing error: {e}"], []

    if not content:
        return [], ["Empty file"]

    # Check root keys order
    root_errors = check_root_keys_order(content)
    errors.extend(root_errors)

    # Check services order
    if "services" in content and isinstance(content["services"], dict):
        for service_name, service_config in content["services"].items():
            service_errors = check_service_keys_order(service_name, service_config)
            errors.extend(service_errors)

    # Check networks usage
    network_errors = check_networks_usage(content, filepath)
    errors.extend(network_errors)

    # Check extends usage
    extends_errors, extends_warnings = check_extends_usage(content, filepath)
    errors.extend(extends_errors)
    warnings.extend(extends_warnings)

    return errors, warnings


def main() -> None:
    """Main entry point."""
    compose_files = sorted(Path(".").rglob("docker-compose.yml"))
    compose_files = [f for f in compose_files if ".venv" not in str(f)]

    logger.info("Validating %d docker-compose.yml files\n", len(compose_files))

    total_errors = 0
    total_warnings = 0
    files_with_issues: list[str] = []

    for filepath in compose_files:
        file_errors, file_warnings = validate_file(filepath)

        if file_errors or file_warnings:
            rel_path = filepath.relative_to(Path("."))
            print(f"\n{rel_path}")

            for error in file_errors:
                print(f"  ERROR: {error}")
                total_errors += 1

            for warning in file_warnings:
                print(f"  WARNING: {warning}")
                total_warnings += 1

            files_with_issues.append(str(rel_path))

    print(f"\n{'=' * 60}")
    print("SUMMARY:")
    print(f"  Files checked: {len(compose_files)}")
    print(f"  Files with issues: {len(files_with_issues)}")
    print(f"  Total errors: {total_errors}")
    print(f"  Total warnings: {total_warnings}")

    if total_errors > 0:
        print("\nFiles with errors:")
        for f in files_with_issues:
            print(f"  - {f}")
        sys.exit(1)
    else:
        print("\nAll files passed validation!")
        sys.exit(0)


if __name__ == "__main__":
    main()
