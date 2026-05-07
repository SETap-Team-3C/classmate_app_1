#!/usr/bin/env python3
"""
Resolve git merge conflict markers by keeping both sides.

Usage: python scripts/resolve_merge_conflicts.py [path]

This script will:
- Walk files under `path` (current directory by default)
- Find conflict markers (<<<<<<<, =======, >>>>>>>)
- Replace each conflict block with the HEAD section followed by the incoming section (both kept)
- Write a backup file with suffix `.orig-conflict` before modifying

Note: Review changes before committing. This tries to preserve content but may need manual tweaks.
"""
import os
import re
import sys

CONFLICT_RE = re.compile(r"^<<<<<<< .*$", re.MULTILINE)
BLOCK_RE = re.compile(r"^<<<<<<< .*?\n(.*?)\n=======(.*?)\n>>>>>>> .*?$", re.DOTALL | re.MULTILINE)


def resolve_text(text: str) -> (str, bool):
    """Return (new_text, changed) where changed is True if any conflict was resolved."""
    if '<<<<<<<' not in text:
        return text, False

    def repl(m):
        head = m.group(1).rstrip('\n')
        incoming = m.group(2).lstrip('\n')
        # Keep both: head first, then incoming separated by a single blank line
        return head + '\n\n' + incoming

    new_text, n = BLOCK_RE.subn(repl, text)
    return new_text, n > 0


def process_file(path: str) -> bool:
    try:
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception:
        return False

    new_content, changed = resolve_text(content)
    if not changed:
        return False

    # backup
    backup = path + '.orig-conflict'
    try:
        if not os.path.exists(backup):
            with open(backup, 'w', encoding='utf-8') as bf:
                bf.write(content)
    except Exception as e:
        print(f'Warning: could not write backup for {path}: {e}')

    with open(path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print(f'Resolved conflicts in {path}')
    return True


def should_process_file(filename: str) -> bool:
    # skip binary-ish and common non-source files
    lower = filename.lower()
    if lower.endswith(('.png', '.jpg', '.jpeg', '.gif', '.lock', '.keystore')):
        return False
    return True


def main(root: str):
    changed_files = []
    for dirpath, dirnames, filenames in os.walk(root):
        # skip .git
        if '.git' in dirpath.split(os.sep):
            continue
        for fn in filenames:
            fp = os.path.join(dirpath, fn)
            if not should_process_file(fn):
                continue
            try:
                with open(fp, 'r', encoding='utf-8') as f:
                    data = f.read()
            except Exception:
                continue
            if '<<<<<<<' in data and '>>>>>>>' in data and '=======' in data:
                ok = process_file(fp)
                if ok:
                    changed_files.append(fp)

    print('\nResolved conflicts in %d files.' % len(changed_files))
    if len(changed_files) > 0:
        print('Backups written with suffix .orig-conflict')


if __name__ == '__main__':
    root = sys.argv[1] if len(sys.argv) > 1 else '.'
    main(root)
