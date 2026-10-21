#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
M5_OUTPUT="${1:-/tmp/frontline-m5-native}"
M5_TEMP=$(mktemp -d /tmp/frontline-m5-native.XXXXXX)
trap 'rm -rf "$M5_TEMP"' EXIT
export XDG_DATA_HOME="$M5_TEMP/data" XDG_CONFIG_HOME="$M5_TEMP/config" XDG_CACHE_HOME="$M5_TEMP/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$M5_OUTPUT"
result=0
timeout 180 "${GODOT_BIN:-godot}" --path . --audio-driver Dummy res://tests/tactical_capture.tscn -- --output="$M5_OUTPUT" > "$M5_TEMP/output.log" 2>&1 || result=$?
cat "$M5_TEMP/output.log"
if [ "$result" -ne 0 ]; then exit "$result"; fi
if rg -q 'SCRIPT ERROR:|ERROR:|WARNING: ObjectDB' "$M5_TEMP/output.log"; then exit 1; fi
