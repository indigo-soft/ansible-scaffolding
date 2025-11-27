#!/usr/bin/env python3
import sys
import json
import os
try:
    import yaml
except ImportError:
    yaml = None
except Exception:
    yaml = None

INV_FILE = sys.argv[1] if len(sys.argv) > 1 else 'inventory/hosts.yml'

# Load inventory via ansible-inventory if available; else parse YAML
def load_inventory_json(path: str):
    from shutil import which
    if which('ansible-inventory'):
        import subprocess
        p = subprocess.run(['ansible-inventory', '-i', path, '--list'], capture_output=True, text=True)
        if p.returncode == 0 and p.stdout.strip():
            return json.loads(p.stdout)
        print("[ERROR]: PyYAML module not found. Install with: pip install PyYAML", file=sys.stderr)
    if yaml is None:
        print("[ERROR]: Python present but PyYAML not installed.", file=sys.stderr)
        sys.exit(2)
    with open(path, 'r', encoding='utf-8') as fh:
        data = yaml.safe_load(fh)
    if not isinstance(data, dict):
        print(f"[ERROR]: Unexpected inventory YAML structure in {path}", file=sys.stderr)
        sys.exit(3)
    # Flatten nested groups
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

# Determine environments
inv = load_inventory_json(INV_FILE)
if 'all' in inv and inv['all'].get('children'):
    ch_all = inv['all'].get('children') or []
    envs = list(ch_all) if not isinstance(ch_all, dict) else list(ch_all.keys())
    envs = [e for e in envs if e not in ('ungrouped', '_meta')]
else:
    groups = [k for k in inv.keys() if not k.startswith('_')]
    children_set = set()
    for g in groups:
        ch = inv.get(g, {}).get('children', []) or []
        if isinstance(ch, dict):
            ch = list(ch.keys())
        for c in ch:
            children_set.add(c)
    envs = [g for g in groups if g not in children_set and g not in ('all','ungrouped')]

# Scaffold group_vars for environments and their child groups
for env in envs:
    gdir = os.path.join('group_vars', env)
    os.makedirs(gdir, exist_ok=True)
    child_groups = inv.get(env, {}).get('children', []) or []
    if isinstance(child_groups, dict):
        child_groups = list(child_groups.keys())
    for cg in child_groups:
        target = os.path.join(gdir, f"{cg}.yml")
        if not os.path.exists(target):
            with open(target, 'w', encoding='utf-8') as fh:
                fh.write(f"# group vars for {env}/{cg}\n")
        else:
            print(f"[INFO]: {target} exists, skipping")

# Scaffold host_vars for hosts under env and its child groups
for env in envs:
    hdir = os.path.join('host_vars', env)
    os.makedirs(hdir, exist_ok=True)
    child_groups = inv.get(env, {}).get('children', []) or []
    if isinstance(child_groups, dict):
        child_groups = list(child_groups.keys())
    for cg in child_groups:
        hosts = inv.get(cg, {}).get('hosts', []) or []
        if isinstance(hosts, dict):
            hosts = list(hosts.keys())
        elif isinstance(hosts, str):
            hosts = hosts.split()
        for h in hosts:
            if not h:
                continue
            target = os.path.join(hdir, f"{h}.yml")
            if not os.path.exists(target):
                with open(target, 'w', encoding='utf-8') as fh:
                    fh.write(f"# host vars for {env}/{h}\n")
            else:
                print(f"[INFO]: {target} exists, skipping")
    direct_hosts = inv.get(env, {}).get('hosts', []) or []
    if isinstance(direct_hosts, dict):
        direct_hosts = list(direct_hosts.keys())
    elif isinstance(direct_hosts, str):
        direct_hosts = direct_hosts.split()
    for h in direct_hosts:
        if not h:
            continue
        target = os.path.join(hdir, f"{h}.yml")
        if not os.path.exists(target):
            with open(target, 'w', encoding='utf-8') as fh:
                fh.write(f"# host vars for {env}/{h}\n")
        else:
            print(f"[INFO]: {target} exists, skipping")

print(f"\033[32m[INFO]: Scaffold completed based on {INV_FILE}\033[0m")
