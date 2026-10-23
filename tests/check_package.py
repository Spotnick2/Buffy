"""Check the exact staged/zip runtime manifest, including dependency bytes and licenses."""
import argparse
import os
from pathlib import Path
import subprocess
import zipfile

parser = argparse.ArgumentParser()
parser.add_argument('package', type=Path)
parser.add_argument('--lua', default='lua')
args = parser.parse_args()
repo = Path(__file__).resolve().parent.parent
os.chdir(repo)
library = Path(os.environ.get('LIBGROUPBUFFS', '../LibGroupBuffs'))
glass = Path(os.environ.get('LIBGLASS', '../LibGlass'))
own = ['Buffy.toc', 'Media/Logo.tga', 'LICENSE', 'THIRD_PARTY_NOTICES.md']
own += [s.strip() for s in Path('Buffy.toc').read_text().splitlines() if s.strip().endswith('.lua') and not s.startswith('#')]
expected = {f'Buffy/{name}': repo / name for name in own}
for folder, root, command in [
    ('LibGroupBuffs-1.0', library, [str(library), 'ship', str(glass)]),
    ('LibGlass-1.0', glass, ['--glass', str(glass), 'ship']),
]:
    files = subprocess.check_output([args.lua, 'tests/libfiles.lua', *command], text=True).splitlines()
    expected.update({f'Buffy/Libs/{folder}/{f}': root / f for f in files})
if args.package.is_dir():
    actual = {p.relative_to(args.package).as_posix(): p.read_bytes() for p in args.package.rglob('*') if p.is_file()}
else:
    with zipfile.ZipFile(args.package) as archive:
        actual = {p: archive.read(p) for p in archive.namelist() if not p.endswith('/')}
assert set(actual) == set(expected), f'Missing: {set(expected)-set(actual)}; extra: {set(actual)-set(expected)}'
for name, source in expected.items():
    if name == 'Buffy/Buffy.toc':
        text = actual[name].decode('utf-8-sig')
        assert '@project-version@' not in text, 'TOC version was not replaced'
        assert '1760483' in text and '16001' in text
        continue
    want, got = source.read_bytes(), actual[name]
    if source.suffix in ('.lua', '.xml', '.md') or source.name == 'LICENSE':
        want, got = want.replace(b'\r\n', b'\n'), got.replace(b'\r\n', b'\n')
    assert want == got, f'Unexpected bytes: {name}'
print(f'Package verified: {len(actual)} runtime files, dependency bytes, logo, and licenses.')
