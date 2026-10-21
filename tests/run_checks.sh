#!/usr/bin/env bash
# Isolate saves and detect Godot errors even when its exit code is zero.
set -euo pipefail
cd "$(dirname "$0")/.."
FRONTLINE_TEST_ROOT=$(mktemp -d /tmp/frontline-checks.XXXXXX)
trap 'rm -rf "$FRONTLINE_TEST_ROOT"' EXIT
export XDG_CONFIG_HOME="$FRONTLINE_TEST_ROOT/config"
export XDG_CACHE_HOME="$FRONTLINE_TEST_ROOT/cache"
export XDG_DATA_HOME="$FRONTLINE_TEST_ROOT/data"
mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME"
GODOT_BIN="${GODOT_BIN:-godot}"
run_check() {
 local result=0
 timeout "${FRONTLINE_CHECK_TIMEOUT:-60}" "$GODOT_BIN" --headless --path . "$@" > "$FRONTLINE_TEST_ROOT/output.log" 2>&1 || result=$?
 cat "$FRONTLINE_TEST_ROOT/output.log"
 if [ "$result" -ne 0 ]; then return "$result"; fi
 if rg -q 'SCRIPT ERROR:|ERROR:|WARNING: ObjectDB' "$FRONTLINE_TEST_ROOT/output.log"; then
  return 1
 fi
}
run_check --editor --import --quit
run_check --quit-after 120
run_check res://tests/m1_mechanics.tscn
run_check --fixed-fps 120 --disable-render-loop res://tests/combat.tscn
run_check --fixed-fps 120 --disable-render-loop res://tests/hybrid.tscn
run_check --fixed-fps 120 --disable-render-loop res://tests/smoke.tscn
run_check res://tests/smoke.tscn -- --verify-save
run_check --fixed-fps 120 --disable-render-loop res://tests/save_validation.tscn
run_check --fixed-fps 120 --disable-render-loop res://tests/campaign.tscn
run_check res://tests/campaign.tscn -- --verify-campaign
run_check --fixed-fps 120 --disable-render-loop res://tests/research.tscn
run_check res://tests/research.tscn -- --verify-research

run_check res://tests/graphics_audit.tscn
run_check res://tests/graphics_audit.tscn -- --verify-graphics
run_check res://tests/ui_design.tscn
run_check res://tests/effects.tscn
run_check res://tests/effects.tscn -- --verify-effects
run_check res://tests/visual_foundation.tscn
run_check res://tests/unit_visuals.tscn
run_check res://tests/environments.tscn
run_check res://tests/environments.tscn -- --verify-environment-settings
run_check res://tests/campaign_catalog.tscn
run_check res://tests/enemy_ai.tscn
FRONTLINE_CHECK_TIMEOUT=180 run_check --fixed-fps 120 --disable-render-loop res://tests/full_campaign.tscn
run_check res://tests/full_campaign.tscn -- --verify-full
FRONTLINE_CHECK_TIMEOUT=90 run_check --fixed-fps 120 --disable-render-loop res://tests/full_campaign.tscn -- --compare
if [ -n "${FRONTLINE_REPORT_DIR:-}" ]; then
 mkdir -p "$FRONTLINE_REPORT_DIR"
 cp "$XDG_DATA_HOME/godot/app_userdata/DRONE KILLER- FRONTLINE/campaign_balance.json" "$FRONTLINE_REPORT_DIR/"
 cp "$XDG_DATA_HOME/godot/app_userdata/DRONE KILLER- FRONTLINE/campaign_comparison.json" "$FRONTLINE_REPORT_DIR/"
fi
