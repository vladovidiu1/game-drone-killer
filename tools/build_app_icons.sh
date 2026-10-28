#!/usr/bin/env bash
# Mechanical packaging only: semantic corner cleanup/cutout/background editing
# is already present in the separately prepared source masters.
set -euo pipefail
cd "$(dirname "$0")/.."
ICON_ROOT=assets/branding
ICON_SOURCES=docs/branding/source
magick "$ICON_SOURCES/icon_full_bleed_master.png" -colorspace sRGB -filter Lanczos -resize 512x512 -alpha off -depth 8 -strip -define png:compression-level=9 "PNG24:$ICON_ROOT/google_play_icon_512.png"
magick "$ICON_SOURCES/icon_full_bleed_master.png" -colorspace sRGB -filter Lanczos -resize 192x192 -alpha off -depth 8 -strip -define png:compression-level=9 "PNG24:$ICON_ROOT/android_launcher_icon_192.png"
ICON_SCALE_PERCENT=$(python3 tools/validate_app_icons.py --foreground-scale "$ICON_SOURCES/adaptive_foreground_master.png")
magick "$ICON_SOURCES/adaptive_foreground_master.png" -trim +repage -filter Lanczos -resize "${ICON_SCALE_PERCENT}%" -background none -gravity center -extent 432x432 -colorspace sRGB -depth 8 -strip -define png:compression-level=9 "PNG32:$ICON_ROOT/android_adaptive_foreground_432.png"
magick "$ICON_SOURCES/adaptive_background_master.png" -colorspace sRGB -filter Lanczos -resize 432x432 -alpha off -depth 8 -strip -define png:compression-level=9 "PNG24:$ICON_ROOT/android_adaptive_background_432.png"
# Android supplies the themed tint: retain exactly the same alpha silhouette.
magick "$ICON_ROOT/android_adaptive_foreground_432.png" -channel RGB -fill white -colorize 100 +channel -depth 8 -strip -define png:compression-level=9 "PNG32:$ICON_ROOT/android_monochrome_432.png"
python3 tools/validate_app_icons.py
bash tools/build_app_icon_preview.sh
python3 tools/build_asset_manifest.py >&2
