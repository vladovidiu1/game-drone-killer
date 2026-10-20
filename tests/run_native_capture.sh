#!/usr/bin/env bash
# Require an actual display; reject engine errors even when Godot returns zero.
set -euo pipefail
cd "$(dirname "$0")/.."
G3_CAPTURE_OUTPUT="${1:-/tmp/frontline-g3-captures}"
G3_CAPTURE_TEMP=$(mktemp -d /tmp/frontline-native.XXXXXX)
trap 'rm -rf "$G3_CAPTURE_TEMP"' EXIT
export XDG_DATA_HOME="$G3_CAPTURE_TEMP/data"
export XDG_CONFIG_HOME="$G3_CAPTURE_TEMP/config"
export XDG_CACHE_HOME="$G3_CAPTURE_TEMP/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$G3_CAPTURE_OUTPUT"
result=0
timeout 180 "${GODOT_BIN:-godot}" --path . --audio-driver Dummy res://tests/unit_capture.tscn -- --output="$G3_CAPTURE_OUTPUT" > "$G3_CAPTURE_TEMP/capture.log" 2>&1 || result=$?
cat "$G3_CAPTURE_TEMP/capture.log"
if [ "$result" -ne 0 ]; then exit "$result"; fi
if rg -q 'SCRIPT ERROR:|ERROR:|WARNING: ObjectDB' "$G3_CAPTURE_TEMP/capture.log"; then exit 1; fi
