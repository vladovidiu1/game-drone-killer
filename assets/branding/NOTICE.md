# Application icon provenance

The publisher supplied the final military-drone/red-targeting-reticle artwork in the task attachment. Prepared versions retain that subject and military appearance. No text, third-party logo or replacement branding was added.

Image-editing preparation:

- Full-bleed artwork: extended the existing dark battlefield into the original white/pre-rounded outer corners (image edit output exec-2cf61c1f-8b8b-4841-b659-c56379b36648).
- Separate foreground: extracted the drone and targeting symbol onto actual alpha, then cleaned its cutout (final image edit output exec-59891d14-ab44-4109-82f7-9ff63606acab).
- Separate background: removed the drone/reticle from the battlefield plate (image edit output exec-80cd3dd3-8a6c-4e4b-9203-f93e91db94a5).

Editable PNG masters are in docs/branding/source, excluded from Godot import/export. Final sizes, RGB/RGBA conversion, safe-zone placement and the monochrome alpha silhouette are reproducibly packaged with ImageMagick by tools/build_app_icons.sh. tools/validate_app_icons.py only reads/validates images and settings.

The supplied original artwork's rights are unchanged. These files are used at the publisher's direction; no third-party rights clearance or reassignment of the original artwork's license is asserted. Assisted edits are subject to applicable image-generation/editing service terms.
