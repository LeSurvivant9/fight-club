#!/usr/bin/env python3
"""Ensure docker-compose files define infrastructure networks as external."""

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

INFRASTRUCTURE_NETWORKS = {"proxy", "media_int", "vpn_net"}


def get_networks_used_by_services(content: dict[str, Any]) -> set[str]:
    """Extract all network names used by services in the compose file."""
    networks_used = set()
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


def update_networks_in_file(filepath: Path) -> bool:
    """Ensure infrastructure networks are defined as external in compose file."""
    try:
        with open(filepath) as f:
            content: dict[str, Any] = yaml.safe_load(f)
    except yaml.YAMLError as e:
        logger.error("YAML parsing error in %s: %s", filepath, e)
        return False

    if not content:
        return True

    updated = False

    networks_used = get_networks_used_by_services(content)
    infrastructure_networks_used = networks_used.intersection(INFRASTRUCTURE_NETWORKS)

    if not infrastructure_networks_used:
        return True

    if "networks" not in content:
        content["networks"] = {}
        updated = True

    root_networks = content.get("networks", {})
    if not isinstance(root_networks, dict):
        root_networks = {}
        content["networks"] = root_networks
        updated = True

    for network_name in infrastructure_networks_used:
        if network_name not in root_networks:
            root_networks[network_name] = {"external": True}
            updated = True
            logger.info("Added external network '%s' to %s", network_name, filepath)
        elif (
            not root_networks[network_name]
            or root_networks[network_name].get("external") is not True
        ):
            root_networks[network_name] = {"external": True}
            updated = True
            logger.info("Updated network '%s' to external in %s", network_name, filepath)

    if updated:
        try:
            with open(filepath, "w") as f:
                yaml.dump(
                    content,
                    f,
                    default_flow_style=False,
                    sort_keys=False,
                    allow_unicode=True,
                    width=120,
                )
            logger.info("Updated: %s", filepath)
            return True
        except Exception as e:
            logger.error("Failed to write %s: %s", filepath, e)
            return False

    return True


def main() -> None:
    """Main entry point."""
    compose_files = list(Path(".").rglob("docker-compose.yml"))
    compose_files = [f for f in compose_files if "infrastructure" not in str(f)]

    if not compose_files:
        logger.info("No docker-compose.yml files found.")
        sys.exit(0)

    logger.info("Found %d docker-compose.yml files to update", len(compose_files))

    updated_count = 0
    failed_count = 0

    for filepath in compose_files:
        if update_networks_in_file(filepath):
            updated_count += 1
        else:
            failed_count += 1

    logger.info("Updated: %d, Failed: %d", updated_count, failed_count)

    if failed_count > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
