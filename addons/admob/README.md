# Pinned AdMob runtime

Poing Studios Godot AdMob v5.1.0, commit 615974e9f66921a54e3c71c33db0856bdbf19d13. MIT notice: LICENSE. Source hashes and the official Godot 4.6.3 native-template SHA-256: PROVENANCE.json.

Only upstream GDScript runtime/version/config files are vendored. The project supplies a small offline Android export plugin in admob.gd; the upstream editor installer, sample scenes, iOS and mediation packages are not enabled. MobileSingletonPlugin intentionally returns null instead of installing implicit editor mocks. The existing opt-in, editor-only simulator remains separate.

Run `python3 tools/setup_android.py` to install checksum-verified bridge AARs. Gradle resolves Google's SDK separately. Missing publisher configuration keeps the provider unavailable, even when its native libraries are packaged. See ../../docs/ADS_SETUP.md.
