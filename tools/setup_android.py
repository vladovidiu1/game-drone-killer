#!/usr/bin/env python3
"""Install verified Android export tools outside the checkout (Linux x86_64)."""
import hashlib
import os
from pathlib import Path
import subprocess
import tarfile
import urllib.request
from urllib.parse import urlparse
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[1]
TOOLS = Path(os.environ.get('FRONTLINE_TOOLS', '/workspace/toolchains')).resolve()
DOWNLOADS = TOOLS / 'downloads'
SDK = TOOLS / 'android-sdk'
JDK = TOOLS / 'jdk-17.0.17+10'
DATA = TOOLS / 'godot-data'
CONFIG = TOOLS / 'godot-config'
TEMPLATES = DATA / 'godot/export_templates/4.6.3.stable'


def fetch(url, filename, digest=None, algorithm='sha256'):
    path = DOWNLOADS / filename
    if not path.exists():
        temporary = path.with_suffix(path.suffix + '.part')
        urllib.request.urlretrieve(url, temporary)
        temporary.replace(path)
    if digest:
        with path.open('rb') as f:
            actual = hashlib.file_digest(f, algorithm).hexdigest()
        if actual != digest:
            raise RuntimeError(f'Checksum mismatch: {path}. Remove the bad download and retry.')
    return path


def extract_zip(path, destination, strip=0):
    destination.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(path) as archive:
        for info in archive.infolist():
            parts = Path(info.filename).parts[strip:]
            if not parts:
                continue
            target = destination.joinpath(*parts).resolve()
            if not target.is_relative_to(destination.resolve()):
                raise RuntimeError('Unsafe archive path')
            if info.is_dir():
                target.mkdir(parents=True, exist_ok=True)
            else:
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(archive.read(info))
                mode = info.external_attr >> 16
                if mode:
                    target.chmod(mode)


def main():
    DOWNLOADS.mkdir(parents=True, exist_ok=True)
    (TOOLS / 'cache').mkdir(exist_ok=True)
    os.environ.setdefault('XDG_CACHE_HOME', str(TOOLS / 'cache'))
    if not subprocess.check_output(['godot', '--version'], text=True).strip().startswith('4.6.3.stable.'):
        raise RuntimeError('Install the standard Godot 4.6.3 stable editor first.')
    jdk = fetch('https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.17%2B10/OpenJDK17U-jdk_x64_linux_hotspot_17.0.17_10.tar.gz',
                'jdk17.tar.gz', '992f96e7995075ac7636bb1a8de52b0c61d71ed3137fafc979ab96b4ab78dd75')
    if not (JDK / 'bin/javac').exists():
        with tarfile.open(jdk) as archive:
            archive.extractall(TOOLS, filter='data')
    fetch('https://github.com/google/bundletool/releases/download/1.18.2/bundletool-all-1.18.2.jar',
          'bundletool-all-1.18.2.jar', '378b5434cd1378bef6b2bc527b8c7f0ff2584b273830335bce54d6d0813c8584')
    base = 'https://github.com/godotengine/godot-builds/releases/download/4.6.3-stable/'
    sums = fetch(base + 'SHA512-SUMS.txt', 'godot-SHA512-SUMS.txt').read_text()
    filename = 'Godot_v4.6.3-stable_export_templates.tpz'
    checksum = next(line.split()[0] for line in sums.splitlines() if line.split()[-1].lstrip('*') == filename)
    archive_path = fetch(base + filename, filename, checksum, 'sha512')
    TEMPLATES.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive_path) as archive:
        for name in ['android_debug.apk', 'android_release.apk', 'android_source.zip', 'version.txt']:
            target = TEMPLATES / name
            if not target.exists():
                target.write_bytes(archive.read('templates/' + name))
    metadata_path = DOWNLOADS / 'android-repository.xml'
    urllib.request.urlretrieve('https://dl.google.com/android/repository/repository2-1.xml', metadata_path)
    metadata = ET.parse(metadata_path).getroot()
    for package, destination in [('cmdline-tools;19.0', SDK / 'cmdline-tools/19.0'),
                                 ('build-tools;36.1.0', SDK / 'build-tools/36.1.0'),
                                 ('platform-tools', SDK / 'platform-tools')]:
        node = next(p for p in metadata.findall('remotePackage') if p.attrib['path'] == package)
        archive = next(a for a in node.findall('./archives/archive') if a.findtext('host-os') == 'linux')
        url = archive.findtext('./complete/url')
        path = fetch('https://dl.google.com/android/repository/' + url, url,
                     archive.findtext('./complete/checksum'), 'sha1')
        if not (destination / 'source.properties').exists():
            extract_zip(path, destination, strip=1)
    license_env = os.environ.copy()
    license_env['JAVA_HOME'] = str(JDK)
    license_env['ANDROID_USER_HOME'] = str(TOOLS / 'android-user')
    (TOOLS / 'android-user').mkdir(exist_ok=True)
    license_command = [str(SDK / 'cmdline-tools/19.0/bin/sdkmanager'), '--sdk_root=' + str(SDK), '--licenses']
    proxy = urlparse(os.environ.get('HTTPS_PROXY', ''))
    if proxy.hostname:
        license_command += ['--proxy=http', '--proxy_host=' + proxy.hostname, '--proxy_port=' + str(proxy.port or 80)]
    if Path('/etc/ssl/certs/java/cacerts').exists():
        license_env['JAVA_TOOL_OPTIONS'] = '-Djavax.net.ssl.trustStore=/etc/ssl/certs/java/cacerts'
    subprocess.run(license_command, input='y\n' * 100, text=True, env=license_env, check=True,
                   stdout=subprocess.DEVNULL, timeout=120)
    # This is the non-extension API 36 platform revision, matching Godot's compile SDK.
    nodes = [p for p in metadata.findall('remotePackage') if p.attrib['path'] == 'platforms;android-36']
    archive = next(a for p in nodes for a in p.findall('./archives/archive')
                   if a.findtext('./complete/url') == 'platform-36_r02.zip')
    path = fetch('https://dl.google.com/android/repository/platform-36_r02.zip', 'platform-36_r02.zip',
                 archive.findtext('./complete/checksum'), 'sha1')
    if not (SDK / 'platforms/android-36/source.properties').exists():
        extract_zip(path, SDK / 'platforms/android-36', strip=1)
    build = ROOT / 'android/build'
    if not (build / 'build.gradle').exists():
        extract_zip(TEMPLATES / 'android_source.zip', build)
        (ROOT / 'android/.build_version').write_text('4.6.3.stable')
    # Verify the Gradle distribution rather than bypassing wrapper integrity checks.
    gradle_sha = fetch('https://services.gradle.org/distributions/gradle-8.11.1-bin.zip.sha256',
                       'gradle-8.11.1.sha256').read_text().strip()
    properties = build / 'gradle/wrapper/gradle-wrapper.properties'
    text = properties.read_text()
    if 'distributionSha256Sum=' not in text:
        properties.write_text(text + '\ndistributionSha256Sum=' + gradle_sha + '\n')
    (CONFIG / 'godot').mkdir(parents=True, exist_ok=True)
    (TOOLS / 'cache').mkdir(exist_ok=True)
    (TOOLS / 'android-user').mkdir(exist_ok=True)
    key = TOOLS / 'debug.keystore'
    if not key.exists():
        subprocess.run([str(JDK / 'bin/keytool'), '-genkeypair', '-keystore', str(key), '-storepass', 'android',
                        '-keypass', 'android', '-alias', 'androiddebugkey', '-keyalg', 'RSA', '-keysize', '2048',
                        '-validity', '10000', '-dname', 'CN=Android Debug,O=Android,C=US'], check=True)
    # Separate editor profile, so existing user editor settings are preserved.
    (CONFIG / 'godot/editor_settings-4.6.tres').write_text(
        '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
        f'export/android/java_sdk_path = "{JDK}"\n'
        f'export/android/android_sdk_path = "{SDK}"\n'
        f'export/android/debug_keystore = "{key}"\n'
        'export/android/debug_keystore_user = "androiddebugkey"\n'
        'export/android/debug_keystore_pass = "android"\n')
    gradle_home = TOOLS / 'gradle-cache'
    gradle_home.mkdir(exist_ok=True)
    settings = 'org.gradle.workers.max=4\norg.gradle.daemon=false\n'
    proxy = urlparse(os.environ.get('HTTPS_PROXY', ''))
    if proxy.hostname:
        if proxy.username or proxy.password:
            raise RuntimeError('Configure authenticated Java proxy securely; credentials must not be saved here.')
        for scheme in ['http', 'https']:
            settings += f'systemProp.{scheme}.proxyHost={proxy.hostname}\nsystemProp.{scheme}.proxyPort={proxy.port or 80}\n'
    if Path('/etc/ssl/certs/java/cacerts').exists():
        settings += 'systemProp.javax.net.ssl.trustStore=/etc/ssl/certs/java/cacerts\n'
    (gradle_home / 'gradle.properties').write_text(settings)
    subprocess.run(['python3', str(ROOT / 'tools/setup_admob.py')], check=True)
    print('Android export prerequisites prepared. Only the debug key was generated; no release key was created.')


if __name__ == '__main__':
    main()
