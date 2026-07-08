"""
Validates that spec files follow their template structure.
Checks that no invented sections exist beyond what the template defines.

Usage: python scripts/validate-specs.py [--specs-dir PATH]
"""

import os
import sys
import re


# Map spec filenames to their template filenames
TEMPLATE_MAP = {
    'product.md': 'product-template.md',
    'requirements.md': 'requirements-template.md',
    'design.md': 'design-template.md',
    'migration-plan.md': 'migration-plan-template.md',
    'test-plan.md': 'test-plan-template.md',
    'tasks.md': 'tasks-template.md',
    'bugfix.md': 'bugfix-template.md',
}

# Architecture docs live in docs/architecture/ or specs/*/architecture/
ARCHITECTURE_TEMPLATE_MAP = {
    'data-model.md': 'architecture/data-model-template.md',
    'api-contract.md': 'architecture/api-contract-template.md',
    'integrations.md': 'architecture/integrations-template.md',
    'security-model.md': 'architecture/security-model-template.md',
    'system-design.md': 'architecture/system-design-template.md',
}


def get_h2_headings(filepath):
    """Extract ## headings from a markdown file."""
    if not os.path.exists(filepath):
        return set()
    headings = set()
    with open(filepath, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if line.startswith('## '):
                # Normalize: lowercase, strip markdown formatting
                heading = line[3:].strip().lower()
                # Remove template placeholders like [xxx]
                heading = re.sub(r'\[.*?\]', '', heading).strip()
                if heading:
                    headings.add(heading)
    return headings


def find_templates_dir(root):
    """Find the specs/_templates/ directory."""
    candidates = [
        os.path.join(root, 'specs', '_templates'),
        os.path.join(root, '.agents', 'templates'),
    ]
    for c in candidates:
        if os.path.isdir(c):
            return c
    return None


def main():
    root = os.getcwd()
    specs_dir = os.path.join(root, 'specs')

    # Parse optional args
    for i, arg in enumerate(sys.argv[1:], 1):
        if arg == '--specs-dir' and i < len(sys.argv) - 1:
            specs_dir = sys.argv[i + 1]

    templates_dir = find_templates_dir(root)
    if not templates_dir:
        print("⏭️ No specs/_templates/ found — skipping validation")
        sys.exit(0)

    if not os.path.isdir(specs_dir):
        print("⏭️ No specs/ directory found — skipping validation")
        sys.exit(0)

    errors = []
    checked = 0

    for dirpath, dirnames, filenames in os.walk(specs_dir):
        # Skip _templates directory itself
        if '_templates' in dirpath:
            continue

        for filename in filenames:
            if filename not in TEMPLATE_MAP:
                continue

            template_name = TEMPLATE_MAP[filename]
            template_path = os.path.join(templates_dir, template_name)

            if not os.path.exists(template_path):
                continue

            spec_path = os.path.join(dirpath, filename)
            spec_headings = get_h2_headings(spec_path)
            template_headings = get_h2_headings(template_path)

            if not template_headings:
                continue

            # Find headings in spec that are NOT in template
            extra = spec_headings - template_headings
            # Filter out common acceptable additions
            acceptable = {'status', 'changelog', 'notas', 'notes', 'approval', 'aprobación'}
            extra = extra - acceptable

            if extra:
                rel_path = os.path.relpath(spec_path, root)
                errors.append(f"  {rel_path}: sections not in template: {sorted(extra)}")

            checked += 1

    # Also validate architecture docs
    arch_dirs = [
        os.path.join(root, 'docs', 'architecture'),
        os.path.join(root, 'specs'),  # some projects put arch docs in specs/
    ]
    for arch_dir in arch_dirs:
        if not os.path.isdir(arch_dir):
            continue
        for dirpath, dirnames, filenames in os.walk(arch_dir):
            if '_templates' in dirpath:
                continue
            for filename in filenames:
                if filename not in ARCHITECTURE_TEMPLATE_MAP:
                    continue
                template_name = ARCHITECTURE_TEMPLATE_MAP[filename]
                template_path = os.path.join(templates_dir, template_name)
                if not os.path.exists(template_path):
                    continue
                spec_path = os.path.join(dirpath, filename)
                spec_headings = get_h2_headings(spec_path)
                template_headings = get_h2_headings(template_path)
                if not template_headings:
                    continue
                extra = spec_headings - template_headings
                acceptable = {'status', 'changelog', 'notas', 'notes', 'approval', 'aprobación'}
                extra = extra - acceptable
                if extra:
                    rel_path = os.path.relpath(spec_path, root)
                    errors.append(f"  {rel_path}: sections not in template: {sorted(extra)}")
                checked += 1

    if errors:
        print(f"❌ Specs with invented sections ({len(errors)} files):")
        for e in errors:
            print(e)
        sys.exit(1)

    if checked == 0:
        print("⏭️ No spec files found to validate")
    else:
        print(f"✅ {checked} spec file(s) validated — all follow templates")
    sys.exit(0)


if __name__ == '__main__':
    main()
