#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
G4_CAPTURE_OUTPUT="${1:-/tmp/frontline-g4-captures}"
G4_CAPTURE_TEMP=$(mktemp -d /tmp/frontline-effects.XXXXXX)
trap 'rm -rf "$G4_CAPTURE_TEMP"' EXIT
export XDG_DATA_HOME="$G4_CAPTURE_TEMP/data"
export XDG_CONFIG_HOME="$G4_CAPTURE_TEMP/config"
export XDG_CACHE_HOME="$G4_CAPTURE_TEMP/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$G4_CAPTURE_OUTPUT"
result=0
timeout 180 "${GODOT_BIN:-godot}" --path . --audio-driver Dummy res://tests/effect_capture.tscn -- --output="$G4_CAPTURE_OUTPUT" "${@:2}" > "$G4_CAPTURE_TEMP/capture.log" 2>&1 || result=$?
cat "$G4_CAPTURE_TEMP/capture.log"
if [ "$result" -ne 0 ]; then exit "$result"; fi
if rg -q 'SCRIPT ERROR:|ERROR:|WARNING: ObjectDB' "$G4_CAPTURE_TEMP/capture.log"; then exit 1; fi
