#!/usr/bin/env python3
"""Record Ubuntu packages needed by the exported Watchman ELF files."""
import os
from pathlib import Path
import re
import subprocess

root = Path('/artifacts/watchman')
env = dict(os.environ, LD_LIBRARY_PATH=str(root / 'lib'))
packages = set()
for path in root.rglob('*'):
    if not path.is_file():
        continue
    with path.open('rb') as file:
        if file.read(4) != b'\x7fELF':
            continue
    result = subprocess.run(['ldd', str(path)], env=env, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if 'not found' in result.stdout:
        raise SystemExit(f'Missing runtime library for {path}:\n{result.stdout}')
    for name in re.findall(r'(?:=>\s+|^\s*)(/\S+)', result.stdout, re.MULTILINE):
        library = Path(name).resolve()
        if library.is_relative_to(root):
            continue
        owner = subprocess.run(['dpkg-query', '-S', str(library)], text=True,
                               stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
        if owner.returncode:
            raise SystemExit(f'No Ubuntu package owns {library}')
        packages.update(line.split(': ')[0].split(':')[0]
                        for line in owner.stdout.splitlines())
(root.parent / 'watchman-runtime-deps.txt').write_text('\n'.join(sorted(packages)) + '\n')
