#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
M1_TEMP=$(mktemp -d /tmp/frontline-m1.XXXXXX)
trap 'rm -rf "$M1_TEMP"' EXIT
export XDG_DATA_HOME="$M1_TEMP/data" XDG_CONFIG_HOME="$M1_TEMP/config" XDG_CACHE_HOME="$M1_TEMP/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
result=0
timeout 300 "${GODOT_BIN:-godot}" --headless --path . res://tests/m1_balance.tscn -- --output="${1:-/tmp/frontline-m1}" > "$M1_TEMP/output.log" 2>&1 || result=$?
cat "$M1_TEMP/output.log"
if [ "$result" -ne 0 ]; then exit "$result"; fi
if rg -q 'SCRIPT ERROR:|ERROR:|WARNING: ObjectDB' "$M1_TEMP/output.log"; then exit 1; fi
