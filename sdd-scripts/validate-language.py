"""
Detects when generated docs are in the wrong language.
If docs_language is 'es' but files contain excessive English headings, it fails.

Usage: python scripts/validate-language.py [--config PATH]
"""

import json
import os
import sys
import re


# Files to check for language compliance
DOCS_TO_CHECK = [
    'docs/product.md',
    'specs/*/requirements.md',
    'specs/*/design.md',
    'specs/*/migration-plan.md',
    'specs/*/test-plan.md',
]

# English section headings that indicate wrong language
ENGLISH_HEADING_PATTERNS = [
    r'^## Overview',
    r'^## Background',
    r'^## Requirements',
    r'^## Scope',
    r'^## Timeline',
    r'^## Assumptions',
    r'^## Executive Summary',
    r'^## Current State',
    r'^## Target State',
    r'^## Dependencies',
    r'^## Risk Assessment',
    r'^## Implementation Plan',
    r'^## Test Strategy',
    r'^## Acceptance Criteria',
]


def find_docs(root):
    """Find all doc files to check using glob-like patterns."""
    files = []
    for pattern in DOCS_TO_CHECK:
        if '*' in pattern:
            # Simple glob: specs/*/requirements.md
            parts = pattern.split('*')
            base_dir = os.path.join(root, parts[0].rstrip('/'))
            suffix = parts[1].lstrip('/')
            if os.path.isdir(base_dir):
                for d in os.listdir(base_dir):
                    candidate = os.path.join(base_dir, d, suffix)
                    if os.path.isfile(candidate):
                        files.append(candidate)
        else:
            candidate = os.path.join(root, pattern)
            if os.path.isfile(candidate):
                files.append(candidate)
    return files


def main():
    root = os.getcwd()

    # Find config
    config_path = os.path.join(root, '.sdd-config.json')
    for i, arg in enumerate(sys.argv[1:], 1):
        if arg == '--config' and i < len(sys.argv) - 1:
            config_path = sys.argv[i + 1]

    if not os.path.exists(config_path):
        print("⏭️ No .sdd-config.json found — skipping language validation")
        sys.exit(0)

    with open(config_path, 'r', encoding='utf-8') as f:
        config = json.load(f)

    lang = config.get('docs_language', 'es')

    if lang != 'es':
        print(f"⏭️ docs_language={lang} — only Spanish validation implemented")
        sys.exit(0)

    docs = find_docs(root)
    if not docs:
        print("⏭️ No doc files found to validate")
        sys.exit(0)

    errors = []
    threshold = 3  # Allow up to 3 English headings (some technical terms OK)

    for filepath in docs:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        english_matches = []
        for pattern in ENGLISH_HEADING_PATTERNS:
            matches = re.findall(pattern, content, re.MULTILINE)
            english_matches.extend(matches)

        if len(english_matches) > threshold:
            rel_path = os.path.relpath(filepath, root)
            errors.append(
                f"  {rel_path}: {len(english_matches)} English headings "
                f"(threshold: {threshold}): {english_matches[:5]}"
            )

    if errors:
        print(f"❌ docs_language=es but English detected:")
        for e in errors:
            print(e)
        sys.exit(1)

    print(f"✅ {len(docs)} doc(s) validated — language OK ({lang})")
    sys.exit(0)


if __name__ == '__main__':
    main()
