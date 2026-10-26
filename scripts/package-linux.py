#!/usr/bin/env python3
"""Package a verified Ubuntu-compatible Flutter bundle as DEB and portable tar."""
import argparse
import hashlib
import json
import re
import shutil
import subprocess
import tarfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--bundle', type=Path, default=root / 'build/linux/x64/release/bundle')
parser.add_argument('--output', type=Path, default=root / 'artifacts/linux')
args = parser.parse_args()
version, number = re.search(r'^version:\s*([\d.]+)\+(\d+)', (root / 'pubspec.yaml').read_text(), re.M).groups()
bundle = args.bundle.resolve()
metadata = json.loads((bundle / 'data/flutter_assets/version.json').read_text())
if (metadata['version'], metadata['build_number']) != (version, number):
    raise SystemExit('Stale Flutter bundle: rebuild before packaging.')
for path in [bundle / 'ciphervault', *(bundle / 'lib').glob('*.so')]:
    info = subprocess.check_output(['readelf', '--version-info', str(path)], text=True)
    versions = [tuple(map(int, s.split('.'))) for s in re.findall(r'GLIBC_(\d+\.\d+)', info)]
    if versions and max(versions) > (2, 35):
        raise SystemExit(f'{path.name} needs a newer glibc; build with Ubuntu 22.04 first.')
output = args.output.resolve()
output.mkdir(parents=True, exist_ok=True)
work = output / 'staging'
if work.exists():
    shutil.rmtree(work)
portable = work / f'CipherVault-{version}-linux-x64'
shutil.copytree(bundle, portable)
for name in ['LICENSE', 'PRIVACY.md', 'THIRD_PARTY.md']:
    shutil.copy2(root / name, portable / name)
(portable / 'README.txt').write_text('CipherVault ' + version + '\n\nRun ./ciphervault from this folder. Keep lib/ and data/ alongside it.\nRequires Linux x86_64, glibc 2.35+, GTK 3, libsecret and desktop GSettings schemas.\nDevelopment preview: test with sample records first.\nSource: https://github.com/idginity124/CipherVault\nLicense: GPL-3.0-only\n')
tar = output / f'CipherVault_{version}_linux_x64.tar.gz'
with tarfile.open(tar, 'w:gz') as archive:
    archive.add(portable, arcname=portable.name)
package = work / 'deb'
app = package / 'opt/ciphervault'
shutil.copytree(portable, app)
(package / 'usr/bin').mkdir(parents=True)
(package / 'usr/bin/ciphervault').symlink_to('/opt/ciphervault/ciphervault')
applications = package / 'usr/share/applications'
applications.mkdir(parents=True)
(applications / 'com.example.ciphervault_mobile.desktop').write_text('[Desktop Entry]\nType=Application\nName=CipherVault\nComment=Offline encrypted password vault\nExec=/opt/ciphervault/ciphervault\nIcon=com.example.ciphervault_mobile\nTerminal=false\nCategories=Utility;Security;\n')
icons = package / 'usr/share/icons/hicolor/256x256/apps'
icons.mkdir(parents=True)
shutil.copy2(root / 'packaging/linux/icon.png', icons / 'com.example.ciphervault_mobile.png')
doc = package / 'usr/share/doc/ciphervault'
doc.mkdir(parents=True)
(doc / 'copyright').write_text('Copyright (c) 2026 Ekrem Bulgan\nLicense: GPL-3.0-only\n\n' + (root / 'LICENSE').read_text())
control = package / 'DEBIAN'
control.mkdir()
size = sum(p.stat().st_size for p in package.rglob('*') if p.is_file() and not p.is_symlink()) // 1024
(control / 'control').write_text(f'''Package: ciphervault
Version: {version}
Section: utils
Priority: optional
Architecture: amd64
Maintainer: Ekrem Bulgan <150246690+idginity124@users.noreply.github.com>
Installed-Size: {size}
Depends: libc6 (>= 2.35), libgtk-3-0 (>= 3.24), libglib2.0-0 (>= 2.64), libsecret-1-0, libstdc++6 (>= 11), libepoxy0, libx11-6, gsettings-desktop-schemas
Homepage: https://github.com/idginity124/CipherVault
Description: Offline encrypted password vault
 Shared Flutter application with encrypted backups and transfers.
 Development preview; not independently security-audited.
''')
deb = output / f'CipherVault_{version}_amd64.deb'
subprocess.run(['dpkg-deb', '--root-owner-group', '--build', str(package), str(deb)], check=True)
(output / 'SHA256SUMS-Linux.txt').write_text(''.join(hashlib.sha256(p.read_bytes()).hexdigest() + '  ' + p.name + '\n' for p in [tar, deb]))
shutil.rmtree(work)
print(tar)
print(deb)
