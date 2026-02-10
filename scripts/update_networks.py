#!/usr/bin/env python3
"""Update docker-compose files to use infrastructure-managed networks."""

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


def update_networks_in_file(filepath: Path) -> bool:
    """Update a single Docker Compose file to use infrastructure networks."""
    try:
        with open(filepath) as f:
            content: dict[str, Any] = yaml.safe_load(f)
    except yaml.YAMLError as e:
        logger.error("YAML parsing error in %s: %s", filepath, e)
        return False

    if not content:
        return True

    updated = False

    if "networks" in content:
        networks = content["networks"]
        if isinstance(networks, dict):
            for network_name in list(networks.keys()):
                if (
                    network_name in INFRASTRUCTURE_NETWORKS
                    and networks[network_name]
                    and networks[network_name].get("external") is True
                ):
                    del networks[network_name]
                    updated = True
                    logger.info("Removed external network '%s' from %s", network_name, filepath)

            if not networks:
                del content["networks"]
                updated = True

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
