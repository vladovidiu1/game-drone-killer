# Android 0.1.1 / version code 2

This update addresses feedback from the first Android AAB test.

- Audio uses explicit stream playback for generated PCM, a separate bounded voice per cue type, and stronger effect levels. Automatic shots, impacts, destruction, construction/upgrades and menu taps now have feedback, alongside the existing primary/reload/radar/result cues. Rate limits bound repeated combat cues. Saved mute and volume remain authoritative; this update does not silently unmute users.
- All six menu scroll areas share native touch scrolling. Gestures starting on paragraphs, images, panels or buttons scroll without buying/activating controls. The volume slider retains its own input, and unrelated fingers retain FIRE/aim ownership. Mouse scrolling remains native.
- Build/upgrade UI no longer changes simulation speed. Successful placement from the shop closes the drawer automatically. Selecting another turret opens its upgrades at normal speed; Pause explicitly stops combat. Enemy, projectile, cooldown, component and transport clocks remain synchronized.
- Build/upgrade actions occupy a separate responsive drawer up to 560 pixels wide, with 18-pixel detail text and a pinned 64-pixel-high upgrade action. Its scrollable content does not compress the independent FIRE/reload/ammunition/ability controls. The drawer updates after field resizing as well as HUD resizing.

## Verification

`./tests/run_checks.sh` includes `tests/mobile_fixes.tscn` and the existing combat, input, campaign/recovery, research, graphics and full-campaign checks. The older quarter-speed assertions now verify normal-speed construction, including component, warning and redeployment clocks. The desktop input fixture clicks a visible HUD control rather than a hidden shop button. Full-mission UI pilots attempt construction/upgrades when affordable and stop re-opening a maxed or unaffordable drawer every frame; paid actions, combat and assertions are unchanged. The smoke and weapon-research watchdogs allow 180 seconds on cloud machines.

Native Compatibility/Mesa rendering is checked separately through `tests/run_ui_capture.sh` and `tests/mobile_fixes.tscn` under X11, including 1280×600, 1024×768, 1600×720 and 1280×720 layouts. These are desktop-rendered fixtures, not physical Android measurements.

An ALSA file-output probe exercised the actual audio mixer with shot, explosion and result cues and produced nonzero mixed PCM (peak 11229 with the tested volume/gain). Waveform checks cover all eleven cue kinds, mute handling and explicit stream playback. This confirms local software output, not the phone speaker, Android audio routing or hardware touch behavior.

`bash tools/export_android.sh unsigned` creates the ARM64 AAB and validates it with bundletool. The GitHub workflow publishes only that AAB and SHA256SUMS, tagged by the exact source commit. No production/upload key is configured here; the unsigned bundle still requires the publisher's existing upload signature before Play Console accepts it.
