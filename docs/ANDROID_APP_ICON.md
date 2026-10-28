# Official Android application icon

The supplied final military-drone/red-targeting-reticle artwork is now the app icon. No text or extra logo was added. The original white/pre-rounded outer corners were replaced with a full-bleed dark battlefield. Google Play and Android apply their own icon masks.

| Asset | Dimensions | Format / role |
| --- | --- | --- |
| `assets/branding/google_play_icon_512.png` | 512 × 512 | RGB, opaque, 336,729 bytes; manual Play Console upload |
| `assets/branding/android_launcher_icon_192.png` | 192 × 192 | RGB, opaque standard launcher icon |
| `assets/branding/android_adaptive_foreground_432.png` | 432 × 432 | RGBA; isolated drone and red reticle, transparent surrounding/gaps |
| `assets/branding/android_adaptive_background_432.png` | 432 × 432 | RGB; separate opaque battlefield/sky plate, no drone or reticle |
| `assets/branding/android_monochrome_432.png` | 432 × 432 | RGBA white silhouette + alpha, system-tinted where themed icons are supported |

The Play PNG is full-color 8-bit RGB, not an indexed PNG, and is below both 512,000 bytes and 512 KiB. The foreground is not a resized copy of the square illustration: the background was removed and a separate background-only layer prepared. The monochrome uses the same isolated silhouette, not a grayscale square image.

## Safe zone

Adaptive layers use the Android 108 dp canvas at 4 px/dp (432 px). All foreground/monochrome nonzero-alpha pixels fit inside the central 66 dp safe circle (132 px radius). The measured radius is 126.343 px, leaving antialias margin. This keeps the complete drone, propellers and red target inside circular and rounded masks. Android's normal 72 dp mask window is shown by the simulated previews.

## Godot 4.6.3 settings

All three existing Android presets use these actual export property names, verified against Godot's tagged 4.6.3 Android exporter source:

- `launcher_icons/main_192x192`
- `launcher_icons/adaptive_foreground_432x432`
- `launcher_icons/adaptive_background_432x432`
- `launcher_icons/adaptive_monochrome_432x432`

Each points to the corresponding PNG above. `project.godot` → `application/config/icon` uses the standard 192 px icon. Existing in-game badge/UI assets remain intact. Godot creates the six density resources for each launcher layer and adaptive XML; manual `android/build` edits are unnecessary.

All non-icon export properties are preserved: package `com.vladovidiu.dronekiller`, versions, signing, architectures, network permissions and backup settings. Advertising configuration/AdMob IDs, gameplay/economy/campaign code and saves are unchanged. No signing key was created or changed.

## Preview and retrieve the Play PNG

- Open [mask previews](branding/icon_preview.png) to compare square/circular/rounded/themed appearances.
- Open the [512 px PNG](../assets/branding/google_play_icon_512.png). On GitHub use **Raw / Download raw file** (or save the raw image), then upload that PNG manually to the Play Console **App icon** graphics field. Upload the PNG, not a screenshot of the preview.
- In Godot: Project → Export → select each Android preset → Launcher Icons to inspect the four references. The project application icon also appears in the editor/project manager.
- For a launcher preview on a phone, install your next build signed with the same existing key as the installed app. Enable themed icons on Android 13+ with a compatible launcher to see the monochrome version. Do not uninstall the existing game just to preview an icon; a differently debug-signed APK will not update a release-signed install. Android launchers may cache icons until the next app update/launcher refresh.

The validation-only debug APK is outside the checkout at `/tmp/drone-icon-validation.apk`; it is for resource inspection and is not a signed release AAB or Play upload. No signed release AAB is generated for this task. Keep the current release configuration and choose a new versionCode only when preparing a subsequent actual Play upload.

## Reproduction and validation

`bash tools/build_app_icons.sh` uses ImageMagick for deterministic PNG sizing/packing from the prepared masters in `docs/branding/source`. `python3 tools/validate_app_icons.py` (Pillow/numpy, read-only) checks PNG headers, dimensions, formats, opacity/transparency, size limit, safe circle, themed silhouette and all preset references. Packaging was rerun and all five files matched byte-for-byte.

`python3 tools/build_asset_manifest.py` updates both asset manifests with accurate publisher-supplied branding provenance. Original rights remain unchanged; see [branding notice](../assets/branding/NOTICE.md).

Godot import/startup and existing visual-resource/UI/smoke suites are run with isolated XDG saves. The debug export is inspected with `python3 tools/validate_app_icon_apk.py /tmp/drone-icon-validation.apk` and Android build-tools, including native mipmap dimensions/transparency and adaptive XML references. These checks are not physical Android launcher/device verification.

Completed validation: 499 visual-resource checks, 201 UI checks, 44 smoke checks and 4 fresh-process save checks passed, plus Godot import/startup. The debug APK passed signature/alignment verification and all 24 native icon density resources were validated; adaptive XML includes foreground, background and monochrome references. Existing signing-key file content was verified unchanged. Physical Android launcher preview remains a device check.
