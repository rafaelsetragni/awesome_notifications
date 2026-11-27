#!/usr/bin/env python3
"""Turns native coverage into one lcov per package, with repo-relative paths.

  split <platform> <lcov>...      lcov (llvm-cov export) -> coverage/<platform>/<package>.lcov
  jacoco <package> <xml>          JaCoCo XML -> coverage/android/<package>.lcov
  summary                         prints every coverage/*/<package>.lcov

A file belongs to the package whose folder holds it; native/ (the shared
engines) belongs to the core, awesome_notifications.
"""
import collections
import glob
import os
import sys
import xml.etree.ElementTree as ET

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
OUT = os.path.join(ROOT, 'coverage')
CORE = 'awesome_notifications'


def package_of(rel):
    if rel.startswith('native/'):
        return CORE
    if rel.startswith('packages/'):
        return rel.split('/')[1]
    return None


def read_records(path):
    """Yields (source path, {line: hits}) from an lcov file."""
    source, lines = None, None
    for raw in open(path):
        raw = raw.strip()
        if raw.startswith('SF:'):
            source, lines = raw[3:], {}
        elif raw.startswith('DA:') and lines is not None:
            number, hits = raw[3:].split(',')[:2]
            lines[int(number)] = lines.get(int(number), 0) + int(hits)
        elif raw == 'end_of_record' and source:
            yield source, lines
            source, lines = None, None


def write(platform, by_package):
    os.makedirs(os.path.join(OUT, platform), exist_ok=True)
    for package, files in by_package.items():
        with open(os.path.join(OUT, platform, package + '.lcov'), 'w') as out:
            for rel in sorted(files):
                lines = files[rel]
                out.write(f'SF:{rel}\n')
                for number in sorted(lines):
                    out.write(f'DA:{number},{lines[number]}\n')
                out.write(f'LF:{len(lines)}\nLH:{sum(1 for h in lines.values() if h)}\nend_of_record\n')


def split(platform, paths):
    by_package = collections.defaultdict(lambda: collections.defaultdict(dict))
    for path in paths:
        for source, lines in read_records(path):
            rel = os.path.relpath(os.path.realpath(source), ROOT)
            package = package_of(rel)
            if package is None or '/tests/' in rel or '/Tests/' in rel or '/example/' in rel:
                continue
            merged = by_package[package][rel]
            for number, hits in lines.items():
                merged[number] = merged.get(number, 0) + hits
    write(platform, by_package)


def jacoco(package, xml_path):
    roots = [os.path.join(ROOT, 'packages', package, 'android', 'src', 'main', d) for d in ('kotlin', 'java')]
    if package == CORE:
        roots.append(os.path.join(ROOT, 'native', 'android', 'AndroidAwnCore', 'src', 'main', 'kotlin'))
    files = {}
    for pkg in ET.parse(xml_path).getroot().findall('package'):
        for sf in pkg.findall('sourcefile'):
            source = next((os.path.join(r, pkg.get('name'), sf.get('name')) for r in roots
                           if os.path.exists(os.path.join(r, pkg.get('name'), sf.get('name')))), None)
            if source is None:
                continue
            rel = os.path.relpath(os.path.realpath(source), ROOT)
            # Every executable line, hit when any of its instructions ran.
            files[rel] = {int(l.get('nr')): int(l.get('ci')) for l in sf.findall('line')}
    write('android', {package: files})


def summary():
    rows = collections.defaultdict(dict)
    for path in sorted(glob.glob(os.path.join(OUT, '*', '*.lcov'))):
        platform = os.path.basename(os.path.dirname(path))
        hit = total = 0
        for _, lines in read_records(path):
            total += len(lines)
            hit += sum(1 for h in lines.values() if h)
        rows[os.path.basename(path)[:-5]][platform] = (hit, total)
    platforms = sorted({p for r in rows.values() for p in r})
    print(f"{'package':40}" + ''.join(f'{p:>22}' for p in platforms))
    for package in sorted(rows):
        cells = ''
        for p in platforms:
            hit, total = rows[package].get(p, (0, 0))
            cells += f'{(f"{hit * 100 / total:.1f}% ({hit}/{total})" if total else "-"):>22}'
        print(f'{package:40}{cells}')


if __name__ == '__main__':
    command = sys.argv[1]
    if command == 'split':
        split(sys.argv[2], sys.argv[3:])
    elif command == 'jacoco':
        jacoco(sys.argv[2], sys.argv[3])
    elif command == 'summary':
        summary()
    else:
        sys.exit(__doc__)
