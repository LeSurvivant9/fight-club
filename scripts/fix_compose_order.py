#!/usr/bin/env python3
"""Fix Docker Compose files key ordering automatically."""

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


def sort_dict_keys(d: dict[str, Any]) -> dict[str, Any]:
    """Sort dictionary keys according to KEY_ORDER."""
    if not isinstance(d, dict):
        return d
    return {k: d[k] for k in sorted(d.keys(), key=get_key_index)}


def fix_service(service_config: dict[str, Any]) -> dict[str, Any]:
    """Fix key ordering in a service configuration."""
    if not isinstance(service_config, dict):
        return service_config

    sorted_service: dict[str, Any] = {}

    for key in sorted(service_config.keys(), key=get_key_index):
        value = service_config[key]

        if isinstance(value, dict):
            sorted_service[key] = sort_dict_keys(value)
        elif isinstance(value, list):
            sorted_service[key] = value
        else:
            sorted_service[key] = value

    return sorted_service


class CustomDumper(yaml.SafeDumper):
    """Custom YAML dumper with custom representers."""

    pass


def str_representer(dumper: CustomDumper, data: str) -> yaml.Node:
    """Represent strings with literal style if multiline."""
    if "\n" in data:
        return dumper.represent_scalar("tag:yaml.org,2002:str", data, style="|")
    return dumper.represent_scalar("tag:yaml.org,2002:str", data)


class FlowStyleList(list[Any]):
    """A list that should be rendered in flow style."""

    pass


class PortsList(list[Any]):
    """A list of ports that should be rendered with quoted strings."""

    pass


def ports_list_representer(dumper: CustomDumper, data: PortsList) -> yaml.Node:
    """Represent PortsList with quoted strings in block style."""
    node = yaml.SequenceNode(tag="tag:yaml.org,2002:seq", value=[], flow_style=False)
    for item in data:
        scalar_node = dumper.represent_scalar("tag:yaml.org,2002:str", str(item), style='"')
        node.value.append(scalar_node)
    return node


def list_representer(dumper: CustomDumper, data: list[Any]) -> yaml.Node:
    """Represent lists - FlowStyleList in flow style, others in block style."""
    if isinstance(data, FlowStyleList):
        return dumper.represent_sequence("tag:yaml.org,2002:seq", data, flow_style=True)
    return dumper.represent_sequence("tag:yaml.org,2002:seq", data, flow_style=False)


def convert_special_lists(obj: Any) -> Any:
    """Convert healthcheck test lists to FlowStyleList and ports to PortsList."""
    if isinstance(obj, dict):
        new_obj: dict[str, Any] = {}
        for key, value in obj.items():
            if key == "healthcheck" and isinstance(value, dict):
                new_healthcheck: dict[str, Any] = {}
                for hk, hv in value.items():
                    if hk == "test" and isinstance(hv, list):
                        new_healthcheck[hk] = FlowStyleList(hv)
                    else:
                        new_healthcheck[hk] = convert_special_lists(hv)
                new_obj[key] = new_healthcheck
            elif key == "ports" and isinstance(value, list):
                new_obj[key] = PortsList(value)
            else:
                new_obj[key] = convert_special_lists(value)
        return new_obj
    elif isinstance(obj, list):
        return [convert_special_lists(item) for item in obj]
    return obj


CustomDumper.add_representer(str, str_representer)
CustomDumper.add_representer(list, list_representer)
CustomDumper.add_representer(FlowStyleList, list_representer)
CustomDumper.add_representer(PortsList, ports_list_representer)


def fix_file(filepath: Path) -> bool:
    """Fix a single Docker Compose file."""
    try:
        with open(filepath) as f:
            content: dict[str, Any] | None = yaml.safe_load(f)
    except yaml.YAMLError as e:
        logger.error("YAML parsing error in %s: %s", filepath, e)
        return False

    if not content:
        logger.info("Empty file: %s", filepath)
        return True

    fixed_content: dict[str, Any] = {}

    root_key_order = ["services", "networks", "configs", "volumes", "secrets"]

    def get_root_key_index(key: str) -> int:
        try:
            return root_key_order.index(key)
        except ValueError:
            return len(root_key_order)

    sorted_root_keys = sorted(content.keys(), key=get_root_key_index)

    for key in sorted_root_keys:
        value = content[key]

        if key == "services" and isinstance(value, dict):
            fixed_services: dict[str, Any] = {}
            for service_name in sorted(value.keys()):
                service_config = value[service_name]
                fixed_services[service_name] = fix_service(service_config)
            fixed_content[key] = fixed_services
        elif isinstance(value, dict):
            fixed_content[key] = sort_dict_keys(value)
        else:
            fixed_content[key] = value

    try:
        content_with_special_lists = convert_special_lists(fixed_content)
        with open(filepath, "w") as f:
            yaml.dump(
                content_with_special_lists,
                f,
                Dumper=CustomDumper,
                default_flow_style=False,
                sort_keys=False,
                allow_unicode=True,
                width=120,
            )
        logger.info("Fixed: %s", filepath)
        return True
    except Exception as e:
        logger.error("Failed to write %s: %s", filepath, e)
        return False


def main() -> None:
    """Main entry point."""
    compose_files = list(Path(".").rglob("docker-compose.yml"))

    if not compose_files:
        logger.info("No docker-compose.yml files found.")
        sys.exit(0)

    logger.info("Found %d docker-compose.yml files", len(compose_files))

    fixed_count = 0
    failed_count = 0

    for filepath in compose_files:
        if fix_file(filepath):
            fixed_count += 1
        else:
            failed_count += 1

    logger.info("Fixed: %d, Failed: %d", fixed_count, failed_count)

    if failed_count > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
