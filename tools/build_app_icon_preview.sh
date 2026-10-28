#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
ICON_PREVIEW_TEMP=$(mktemp -d /tmp/frontline-icon-preview.XXXXXX)
trap 'rm -rf "$ICON_PREVIEW_TEMP"' EXIT
mkdir -p docs/branding
magick assets/branding/android_adaptive_background_432.png assets/branding/android_adaptive_foreground_432.png -compose Over -composite -gravity center -crop 288x288+0+0 +repage "$ICON_PREVIEW_TEMP/adaptive.png"
magick -size 288x288 xc:none -fill white -draw 'circle 143.5,143.5 143.5,0' "$ICON_PREVIEW_TEMP/circle_mask.png"
magick -size 288x288 xc:none -fill white -draw 'roundrectangle 0,0 287,287 70,70' "$ICON_PREVIEW_TEMP/round_mask.png"
for shape in circle round; do
 magick "$ICON_PREVIEW_TEMP/adaptive.png" "$ICON_PREVIEW_TEMP/${shape}_mask.png" -alpha off -compose CopyOpacity -composite "$ICON_PREVIEW_TEMP/$shape.png"
done
magick assets/branding/android_monochrome_432.png -gravity center -crop 288x288+0+0 +repage "$ICON_PREVIEW_TEMP/mono.png"
magick -size 288x288 xc:'#142128' "$ICON_PREVIEW_TEMP/mono.png" -compose Over -composite "$ICON_PREVIEW_TEMP/circle_mask.png" -alpha off -compose CopyOpacity -composite "$ICON_PREVIEW_TEMP/mono_dark.png"
magick assets/branding/google_play_icon_512.png -resize 256x256 -background '#20242b' -gravity center -extent 280x280 "$ICON_PREVIEW_TEMP/play_panel.png"
for shape in circle round; do
 magick "$ICON_PREVIEW_TEMP/$shape.png" -resize 256x256 -background '#20242b' -gravity center -extent 280x280 "$ICON_PREVIEW_TEMP/${shape}_panel.png"
done
magick "$ICON_PREVIEW_TEMP/mono_dark.png" -resize 256x256 -background '#20242b' -gravity center -extent 280x280 "$ICON_PREVIEW_TEMP/mono_panel.png"
magick "$ICON_PREVIEW_TEMP/play_panel.png" "$ICON_PREVIEW_TEMP/circle_panel.png" "$ICON_PREVIEW_TEMP/round_panel.png" "$ICON_PREVIEW_TEMP/mono_panel.png" +append docs/branding/icon_preview.png
