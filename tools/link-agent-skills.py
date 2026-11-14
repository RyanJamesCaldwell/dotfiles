#!/usr/bin/env python3
"""Explicit, no-overwrite skill linking after a separate private repo checkout."""
import argparse
import os
from pathlib import Path
import subprocess

PIN = 'c3433bb6984a5ac0e62ac3d5ca84f463d84d2691'
SKILLS = ('monarch-cli', 'reverse-engineer-anything', 'oura-boros', 'rex')
PSTACK_SKILLS = ('arena', 'bro', 'how', 'teach', 'unslop', 'why', 'architect')
AVAILABLE_SKILLS = SKILLS + PSTACK_SKILLS


def plan(source, home, skills=SKILLS):
    skills = tuple(skills)
    if not skills or len(set(skills)) != len(skills):
        raise ValueError('Choose one or more distinct skills')
    if any(name not in AVAILABLE_SKILLS for name in skills):
        raise ValueError('Unknown skill selection')
    source = source.resolve()
    if subprocess.check_output(['git', '-C', str(source), 'rev-parse', 'HEAD'], text=True).strip() != PIN:
        raise ValueError('Checkout must be at the reviewed commit ' + PIN)
    if subprocess.check_output(['git', '-C', str(source), 'status', '--porcelain', '--untracked-files=all', '--ignored'], text=True).strip():
        raise ValueError('Skill checkout must be clean')
    links = []
    for name in skills:
        target = source / 'skills' / name
        if not (target / 'SKILL.md').is_file():
            raise ValueError('Missing skill: ' + name)
        # A second discovery location can load stale duplicates. Never remove it.
        for root in ('.agents', '.codex'):
            dest = home / root / 'skills' / name
            if os.path.lexists(dest):
                if root == '.agents' and dest.is_symlink() and dest.resolve() == target:
                    continue
                raise ValueError('Existing skill requires manual review: ' + str(dest))
        dest = home / '.agents' / 'skills' / name
        if not os.path.lexists(dest):
            links.append((dest, target))
    return links


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, default=Path.home() / '.local' / 'share' / 'agent-skills')
    parser.add_argument('--skills', nargs='+', choices=AVAILABLE_SKILLS, default=SKILLS,
                        help='Link only these skills; default is the original four')
    parser.add_argument('--apply', action='store_true', help='Create missing symlinks; default is preview only')
    args = parser.parse_args()
    try:
        links = plan(args.source, Path.home(), args.skills)
        for dest, target in links:
            print(f'{dest} -> {target}')
        if args.apply:
            for dest, target in links:
                dest.parent.mkdir(parents=True, exist_ok=True)
                # symlink() refuses a concurrently-created destination.
                dest.symlink_to(target)
        print('Applied.' if args.apply else 'Preview only; no changes made.')
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        parser.exit(1, f'{error}\n')


if __name__ == '__main__':
    main()
