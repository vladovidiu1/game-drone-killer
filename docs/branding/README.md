# App icon preview and editable sources

`icon_preview.png`, from left to right: full-bleed Play Store icon, circular adaptive mask, rounded-square adaptive mask, example dark themed monochrome mask. These are software mask previews, not Android device screenshots. Launcher shapes and themed tint colors depend on the device/launcher.

The three `source/*.png` files are the prepared high-resolution masters (full artwork, isolated foreground, background plate). `.gdignore` keeps these working images and previews out of Godot import/export. They do not replace any gameplay artwork.

See ../ANDROID_APP_ICON.md for exact asset paths, configuration, validation and Play Store download instructions. Rebuild the packaged PNGs with `bash tools/build_app_icons.sh` from the repository root.
