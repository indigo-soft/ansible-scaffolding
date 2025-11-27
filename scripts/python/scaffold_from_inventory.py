#!/usr/bin/env python3
"""Scaffold group_vars and host_vars from Ansible inventory."""
import sys
import json
import os
from pathlib import Path
from typing import Dict, List, Optional
try:
    import yaml
except ImportError:
    yaml = None


class InventoryLoader:
    """Load and parse Ansible inventory."""

    def __init__(self, inventory_path: str):
        self.inventory_path = inventory_path

    def load(self) -> Dict:
        """Load inventory using ansible-inventory or YAML parser."""
        inv_data = self._try_ansible_inventory() or self._parse_yaml()
        return self._flatten_groups(inv_data)

    def _try_ansible_inventory(self) -> Optional[Dict]:
        """Try to load inventory via ansible-inventory command."""
        from shutil import which
        if not which('ansible-inventory'):
            return None
        import subprocess
        result = subprocess.run(
            ['ansible-inventory', '-i', self.inventory_path, '--list'],
            capture_output=True,
            text=True
        )
        if result.returncode == 0 and result.stdout.strip():
            return json.loads(result.stdout)
        return None

    def _parse_yaml(self) -> Dict:
        """Parse inventory YAML file."""
        if yaml is None:
            print("[ERROR]: PyYAML not installed. Install: pip install PyYAML", file=sys.stderr)
            sys.exit(2)
        with open(self.inventory_path, 'r', encoding='utf-8') as fh:
            data = yaml.safe_load(fh)
        if not isinstance(data, dict):
            print(f"[ERROR]: Invalid inventory structure in {self.inventory_path}", file=sys.stderr)
            sys.exit(3)
        return data

    def _flatten_groups(self, data: Dict) -> Dict:
        """Flatten nested group structure."""
        # Check if this is ansible-inventory JSON output (has _meta)
        if '_meta' in data:
            # ansible-inventory already provides flattened structure
            # Just filter out _meta and all groups
            out = {}
            for group_name, group_data in data.items():
                if group_name not in ('_meta', 'all') and isinstance(group_data, dict):
                    children = group_data.get('children', [])
                    hosts = group_data.get('hosts', [])
                    out[group_name] = {'children': children, 'hosts': hosts}
            return out

        # Original YAML parsing logic
        out = {}

        def collect_groups(node, name=None):
            if not isinstance(node, dict):
                return
            children = node.get('children') or {}
            hosts = node.get('hosts') or []
            if isinstance(hosts, dict):
                hosts = list(hosts.keys())
            if isinstance(children, dict):
                child_keys = list(children.keys())
            else:
                child_keys = children
            if name:
                out[name] = {'children': child_keys, 'hosts': hosts}
            if isinstance(children, dict):
                for child_name, child_node in children.items():
                    collect_groups(child_node or {}, child_name)

        if 'all' in data and isinstance(data['all'], dict):
            collect_groups(data['all'], None)
        else:
            for k, v in data.items():
                collect_groups(v, k)

        return out


class EnvironmentDetector:
    """Detect environment groups from inventory."""

    def __init__(self, inventory: Dict):
        self.inventory = inventory

    def detect(self) -> List[str]:
        """Detect top-level environment groups."""
        if 'all' in self.inventory and self.inventory['all'].get('children'):
            ch_all = self.inventory['all'].get('children') or []
            envs = list(ch_all) if not isinstance(ch_all, dict) else list(ch_all.keys())
            return [e for e in envs if e not in ('ungrouped', '_meta')]

        groups = [k for k in self.inventory.keys() if not k.startswith('_')]
        children_set = set()
        for g in groups:
            ch = self.inventory.get(g, {}).get('children', []) or []
            if isinstance(ch, dict):
                ch = list(ch.keys())
            for c in ch:
                children_set.add(c)
        return [g for g in groups if g not in children_set and g not in ('all', 'ungrouped')]


class Scaffolder:
    """Scaffold group_vars and host_vars directories."""

    def __init__(self, inventory: Dict, template_dir: str = 'scripts/templates/scaffolding'):
        self.inventory = inventory
        self.template_dir = Path(template_dir)
        self.host_vars_template = self._load_template('host_vars_item.yml')

    def _load_template(self, filename: str) -> str:
        """Load template file content."""
        template_path = self.template_dir / filename
        if template_path.exists():
            return template_path.read_text(encoding='utf-8')
        return f"# {filename} template not found\n"

    def scaffold_group_vars(self, environments: List[str]):
        """Create group_vars directory structure."""
        for env in environments:
            gdir = Path('group_vars') / env
            gdir.mkdir(parents=True, exist_ok=True)

            child_groups = self.inventory.get(env, {}).get('children', []) or []
            if isinstance(child_groups, dict):
                child_groups = list(child_groups.keys())

            for cg in child_groups:
                target = gdir / f"{cg}.yml"
                if not target.exists():
                    target.write_text(f"# group vars for {env}/{cg}\n", encoding='utf-8')
                    print(f"[INFO]: Created {target}")
                else:
                    print(f"[INFO]: {target} exists, skipping")

    def scaffold_host_vars(self, environments: List[str]):
        """Create host_vars directory structure."""
        for env in environments:
            hdir = Path('host_vars') / env
            hdir.mkdir(parents=True, exist_ok=True)

            # Process child groups
            child_groups = self.inventory.get(env, {}).get('children', []) or []
            if isinstance(child_groups, dict):
                child_groups = list(child_groups.keys())

            for cg in child_groups:
                hosts = self._get_hosts(cg)
                for host in hosts:
                    self._create_host_file(hdir, host)

            # Process direct hosts
            direct_hosts = self._get_hosts(env)
            for host in direct_hosts:
                self._create_host_file(hdir, host)

    def _get_hosts(self, group: str) -> List[str]:
        """Extract hosts from group."""
        hosts = self.inventory.get(group, {}).get('hosts', []) or []
        if isinstance(hosts, dict):
            return list(hosts.keys())
        if isinstance(hosts, str):
            return hosts.split()
        return [h for h in hosts if h]

    def _create_host_file(self, directory: Path, hostname: str):
        """Create host_vars file from template."""
        if not hostname:
            return
        target = directory / f"{hostname}.yml"
        if not target.exists():
            target.write_text(self.host_vars_template, encoding='utf-8')
            print(f"[INFO]: Created {target}")
        else:
            print(f"[INFO]: {target} exists, skipping")


def main():
    """Main entry point."""
    inv_file = sys.argv[1] if len(sys.argv) > 1 else 'inventory/hosts.yml'

    # Load and process inventory
    loader = InventoryLoader(inv_file)
    inventory = loader.load()

    # Detect environments
    detector = EnvironmentDetector(inventory)
    environments = detector.detect()

    if not environments:
        print("[WARN]: No environments detected in inventory")
    else:
        print(f"[INFO]: Detected environments: {', '.join(environments)}")

    # Scaffold structure
    scaffolder = Scaffolder(inventory)
    scaffolder.scaffold_group_vars(environments)
    scaffolder.scaffold_host_vars(environments)

    print(f"\033[32m[INFO]: Scaffold completed based on {inv_file}\033[0m")


if __name__ == '__main__':
    main()
