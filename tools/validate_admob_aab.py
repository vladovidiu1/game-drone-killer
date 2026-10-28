#!/usr/bin/env python3
"""Inspect a real unsigned Android bundle; this is not on-device ad evidence."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[1]
TOOLS = Path(os.environ.get('FRONTLINE_TOOLS', '/workspace/toolchains'))
ANDROID = '{http://schemas.android.com/apk/res/android}'
APP_ID = 'ca-app-pub-3787873725289108~4168159841'
TEST_UNIT = 'ca-app-pub-3940256099942544/5224354917'


def validate(bundle: Path) -> dict:
    command = [str(TOOLS / 'jdk-17.0.17+10/bin/java'), '-jar',
               str(TOOLS / 'downloads/bundletool-all-1.18.2.jar')]
    subprocess.run(command + ['validate', f'--bundle={bundle}'],
                   check=True, capture_output=True, text=True)
    manifest = subprocess.check_output(command + ['dump', 'manifest',
                   f'--bundle={bundle}', '--module=base'], text=True)
    root = ET.fromstring(manifest)
    assert root.get('package') == 'com.vladovidiu.dronekiller'
    assert int(root.get(ANDROID + 'versionCode')) >= 5
    application = root.find('application')
    assert application is not None
    assert application.get(ANDROID + 'debuggable', 'false') == 'false'
    assert application.get(ANDROID + 'allowBackup') == 'false'
    metadata = {m.get(ANDROID + 'name'): m.get(ANDROID + 'value')
                for m in application.findall('meta-data')}
    assert metadata.get('com.google.android.gms.ads.APPLICATION_ID') == APP_ID
    plugins = ['PoingGodotAdMob', 'PoingGodotAdMobRewardedAd',
               'PoingGodotAdMobConsentInformation', 'PoingGodotAdMobUserMessagingPlatform']
    for name in plugins:
        assert metadata.get('org.godotengine.plugin.v2.' + name) == (
            'com.poingstudios.godot.admob.ads.' + name), name
    permissions = {p.get(ANDROID + 'name') for p in root.findall('uses-permission')}
    for permission in ['android.permission.INTERNET', 'android.permission.ACCESS_NETWORK_STATE']:
        assert permission in permissions, permission
    with zipfile.ZipFile(bundle) as archive:
        names = archive.namelist()
        assert not any(n.upper().endswith(('.RSA', '.DSA', '.EC', '.SF')) for n in names)
        config_path = next(n for n in names if n.endswith('/assets/data/advertising.json'))
        config = json.loads(archive.read(config_path))
        assert config == json.loads((ROOT / 'data/advertising.json').read_text())
        assert config['mode'] == 'test'
        assert config['android_app_id'] == APP_ID
        assert config['android_rewarded_test_id'] == TEST_UNIT
        assert config['android_rewarded_id'] == 'ca-app-pub-3787873725289108/8579720139'
        if not config['compliance_reviewed']:
            assert not config['enabled']
        if config['enabled']:
            assert config['compliance_reviewed'] and config['privacy_messaging_configured']
            assert config['audience'] == 'reviewed_adult_only'
            assert config['privacy_policy_url'].startswith('https://')
        dex = b''.join(archive.read(n) for n in names if n.endswith('.dex'))
        classes = ['com/google/android/libraries/ads/mobile/sdk/MobileAds',
                   'com/google/android/ump/UserMessagingPlatform',
                   'com/google/android/ump/ConsentInformation',
                   'org/godotengine/godot/plugin/AndroidRuntimePlugin'] + [
                       'com/poingstudios/godot/admob/ads/' + p for p in plugins]
        for name in classes:
            assert ('L' + name + ';').encode() in dex, name
        methods = ['canRequestAds', 'requestConsentInfoUpdate', 'loadConsentForm',
                   'showPrivacyOptionsForm', 'getConsentInformation',
                   'on_consent_info_updated_success', 'on_consent_form_dismissed',
                   'on_initialization_complete', 'on_rewarded_ad_loaded',
                   'on_rewarded_ad_failed_to_load', 'on_rewarded_ad_user_earned_reward']
        for name in methods:
            assert name.encode() + b'\0' in dex, name
        assert any(n.startswith('base/lib/arm64-v8a/') for n in names)
        assert not any(n.startswith('base/lib/x86') for n in names)
    return {'bundle': str(bundle), 'bytes': bundle.stat().st_size,
            'package': root.get('package'), 'version_code': root.get(ANDROID + 'versionCode'),
            'version_name': root.get(ANDROID + 'versionName'), 'unsigned': True,
            'native_sdk': 'Google Mobile Ads Next-Gen 1.4.0; UMP 4.0.0 (Gradle resolved)',
            'native_classes_checked': classes, 'native_methods_signals_checked': methods,
            'app_id_manifest': metadata['com.google.android.gms.ads.APPLICATION_ID'],
            'required_permissions': sorted(permissions), 'advertising_mode': config['mode'],
            'advertising_enabled': config['enabled'],
            'privacy_policy_url': config['privacy_policy_url'],
            'activation_blockers': [name for name, satisfied in {
                'publisher_activation': config['enabled'],
                'supported_audience_confirmed': config['audience'] == 'reviewed_adult_only',
                'admob_privacy_messages_confirmed': config['privacy_messaging_configured'],
                'publisher_privacy_review_completed': config['compliance_reviewed'],
            }.items() if not satisfied],
            'physical_android_ad_display_verified': False}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('bundle', type=Path)
    print(json.dumps(validate(parser.parse_args().bundle), indent=2))
