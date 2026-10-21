#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
G6_PROFILE_OUTPUT="${1:-/tmp/frontline-profile}"
G6_PROFILE_SCENE="${FRONTLINE_CAPTURE_SCENE:-res://tests/graphics_profile_capture.tscn}"
G6_PROFILE_TEMP=$(mktemp -d /tmp/frontline-profile.XXXXXX)
trap 'rm -rf "$G6_PROFILE_TEMP"' EXIT
export XDG_DATA_HOME="$G6_PROFILE_TEMP/data" XDG_CONFIG_HOME="$G6_PROFILE_TEMP/config" XDG_CACHE_HOME="$G6_PROFILE_TEMP/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$G6_PROFILE_OUTPUT"
result=0
timeout 180 "${GODOT_BIN:-godot}" --path . --audio-driver Dummy "$G6_PROFILE_SCENE" -- --output="$G6_PROFILE_OUTPUT" "${@:2}" > "$G6_PROFILE_TEMP/output.log" 2>&1 || result=$?
cat "$G6_PROFILE_TEMP/output.log"
if [ "$result" -ne 0 ]; then exit "$result"; fi
if rg -q 'SCRIPT ERROR:|ERROR:|WARNING: ObjectDB' "$G6_PROFILE_TEMP/output.log"; then exit 1; fi
