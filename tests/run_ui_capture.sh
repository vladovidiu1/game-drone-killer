#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
G5_CAPTURE_OUTPUT="${1:-/tmp/frontline-g5-captures}"
G5_CAPTURE_TEMP=$(mktemp -d /tmp/frontline-ui.XXXXXX)
trap 'rm -rf "$G5_CAPTURE_TEMP"' EXIT
export XDG_DATA_HOME="$G5_CAPTURE_TEMP/data"
export XDG_CONFIG_HOME="$G5_CAPTURE_TEMP/config"
export XDG_CACHE_HOME="$G5_CAPTURE_TEMP/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$G5_CAPTURE_OUTPUT"
result=0
timeout 180 "${GODOT_BIN:-godot}" --path . --audio-driver Dummy res://tests/ui_capture.tscn -- --output="$G5_CAPTURE_OUTPUT" > "$G5_CAPTURE_TEMP/capture.log" 2>&1 || result=$?
cat "$G5_CAPTURE_TEMP/capture.log"
if [ "$result" -ne 0 ]; then exit "$result"; fi
if rg -q 'SCRIPT ERROR:|ERROR:|WARNING: ObjectDB' "$G5_CAPTURE_TEMP/capture.log"; then exit 1; fi
