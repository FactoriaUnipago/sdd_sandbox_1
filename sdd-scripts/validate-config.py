"""
Validates that .sdd-config.json only contains fields defined in the template.
Prevents agents from inventing new config fields.

Usage: python scripts/validate-config.py [--config PATH] [--template PATH]
"""

import json
import sys
import os


def get_keys(d, prefix=''):
    """Recursively extract all keys from a dict."""
    keys = set()
    for k, v in d.items():
        full = f"{prefix}.{k}" if prefix else k
        keys.add(full)
        if isinstance(v, dict):
            keys |= get_keys(v, full)
    return keys


def find_file(name, search_paths):
    """Find a file in common project locations."""
    for path in search_paths:
        full = os.path.join(path, name)
        if os.path.exists(full):
            return full
    return None


def main():
    # Parse optional args
    config_path = None
    template_path = None
    for i, arg in enumerate(sys.argv[1:], 1):
        if arg == '--config' and i < len(sys.argv) - 1:
            config_path = sys.argv[i + 1]
        elif arg == '--template' and i < len(sys.argv) - 1:
            template_path = sys.argv[i + 1]

    # Find files
    root = os.getcwd()
    if not config_path:
        config_path = find_file('.sdd-config.json', [root])
    if not template_path:
        template_path = find_file('.sdd-config.template.json', [
            root,
            os.path.join(root, '.agents'),
            os.path.join(root, '.agents', 'rules'),
        ])

    if not config_path or not os.path.exists(config_path):
        print("⏭️ No .sdd-config.json found — skipping validation")
        sys.exit(0)

    if not template_path or not os.path.exists(template_path):
        print("⏭️ No .sdd-config.template.json found — skipping validation")
        sys.exit(0)

    with open(template_path, 'r', encoding='utf-8-sig') as f:
        template = json.load(f)
    with open(config_path, 'r', encoding='utf-8-sig') as f:
        config = json.load(f)

    template_keys = get_keys(template)
    config_keys = get_keys(config)

    # Keys where ANY segment starts with _ are internal metadata, always allowed
    config_keys = {k for k in config_keys if not any(seg.startswith('_') for seg in k.split('.'))}
    template_keys = {k for k in template_keys if not any(seg.startswith('_') for seg in k.split('.'))}

    extra = config_keys - template_keys
    if extra:
        print(f"❌ Config has fields not in template:")
        for k in sorted(extra):
            print(f"   - {k}")
        sys.exit(1)

    # --- Value validation: enum constraints ---
    VALID_VALUES = {
        'role': ['analyst', 'developer', 'qa', ''],
        'project_type': ['new', 'existing', 'migration', ''],
        'verbosity': ['detailed', 'brief'],
        'docs_language': ['es', 'en'],
        'repo_type': ['monorepo', 'single', 'multi', ''],
        'host': ['github', 'azure', ''],
        'project_host': ['github', 'azure', ''],
    }

    VALID_STACKS = [
        'angular', 'aws', 'capacitor', 'dotnet', 'flutter',
        'java', 'node', 'python', 'react', 'typescript',
    ]

    VALID_DEPLOYMENT_PATTERNS = [
        'fullstack-vercel', 'monorepo-split', 'multi-repo',
        'backend-only', 'frontend-only',
        'mobile-capacitor', 'hybrid', 'mobile-flutter', '',
    ]

    VALID_DEPLOYMENT_PROVIDERS = [
        'aws', 'vercel', 'azure', 'on-premise', '',
    ]

    VALID_MIGRATION_STRATEGIES = [
        'strangler-fig', 'big-bang', 'parallel-run', 'blue-green', '',
    ]

    value_errors = []

    # Check enum fields
    for field, allowed in VALID_VALUES.items():
        val = config.get(field, '')
        if val and val not in allowed:
            value_errors.append(f"   - {field}: '{val}' not in {allowed}")

    # Check stacks array
    stacks = config.get('stacks', [])
    if isinstance(stacks, list):
        for s in stacks:
            if s not in VALID_STACKS:
                value_errors.append(f"   - stacks: '{s}' not a known stack {VALID_STACKS}")

    # Check deployment values
    deployment = config.get('deployment', {})
    if isinstance(deployment, dict):
        pattern = deployment.get('pattern', '')
        if pattern and pattern not in VALID_DEPLOYMENT_PATTERNS:
            value_errors.append(f"   - deployment.pattern: '{pattern}' not in {VALID_DEPLOYMENT_PATTERNS}")
        provider = deployment.get('provider', '')
        if provider and provider not in VALID_DEPLOYMENT_PROVIDERS:
            value_errors.append(f"   - deployment.provider: '{provider}' not in {VALID_DEPLOYMENT_PROVIDERS}")

    # Check migration values
    migration = config.get('migration', {})
    if isinstance(migration, dict):
        strategy = migration.get('strategy', '')
        if strategy and strategy not in VALID_MIGRATION_STRATEGIES:
            value_errors.append(f"   - migration.strategy: '{strategy}' not in {VALID_MIGRATION_STRATEGIES}")

    if value_errors:
        print(f"❌ Config has invalid values:")
        for e in value_errors:
            print(e)
        sys.exit(1)

    print("✅ .sdd-config.json — all fields and values valid")
    sys.exit(0)


if __name__ == '__main__':
    main()
