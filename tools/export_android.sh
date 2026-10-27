#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
FRONTLINE_TOOLS="${FRONTLINE_TOOLS:-/workspace/toolchains}"
export JAVA_HOME="$FRONTLINE_TOOLS/jdk-17.0.17+10"
export ANDROID_HOME="$FRONTLINE_TOOLS/android-sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export ANDROID_USER_HOME="$FRONTLINE_TOOLS/android-user"
export GRADLE_USER_HOME="$FRONTLINE_TOOLS/gradle-cache"
export XDG_CONFIG_HOME="$FRONTLINE_TOOLS/godot-config"
export XDG_DATA_HOME="$FRONTLINE_TOOLS/godot-data"
export XDG_CACHE_HOME="$FRONTLINE_TOOLS/cache"
mkdir -p export
case "${1:-debug}" in
  debug) godot --headless --path . --export-debug 'Android Test APK' export/drone-killer-test.apk
    "$ANDROID_HOME/build-tools/36.1.0/apksigner" verify --verbose export/drone-killer-test.apk
    "$ANDROID_HOME/build-tools/36.1.0/zipalign" -c -P 16 4 export/drone-killer-test.apk ;;
  unsigned) godot --headless --path . --export-release 'Google Play AAB Unsigned' export/drone-killer-unsigned.aab
    java_bundle="$FRONTLINE_TOOLS/downloads/bundletool-all-1.18.2.jar"
    "$JAVA_HOME/bin/java" -jar "$java_bundle" validate --bundle=export/drone-killer-unsigned.aab > export/bundle-validation.txt
    echo 'Unsigned AAB structure validated; upload signing is still required.' ;;
  release)
    : "${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:?Set the upload keystore path securely}"
    : "${GODOT_ANDROID_KEYSTORE_RELEASE_USER:?Set the upload key alias}"
    : "${GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD:?Set the upload password securely}"
    godot --headless --path . --export-release 'Google Play AAB' export/drone-killer.aab
    "$JAVA_HOME/bin/jarsigner" -verify export/drone-killer.aab
    "$JAVA_HOME/bin/java" -jar "$FRONTLINE_TOOLS/downloads/bundletool-all-1.18.2.jar" validate --bundle=export/drone-killer.aab > export/bundle-validation.txt ;;
  *) echo 'Usage: bash tools/export_android.sh [debug|unsigned|release]' >&2; exit 2 ;;
esac
