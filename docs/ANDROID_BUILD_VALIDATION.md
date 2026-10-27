# Android export preparation validation — 2026-10-27

Validated in the cloud onboarding Linux environment with Godot 4.6.3 stable:

- `tests/run_checks.sh`: exit 0; 38 suite summaries, 75,285 reported checks, zero failures. Includes startup, actual combat, tutorial, mission performance, components, placement, campaign/research/economy/recovery transactions, resource checks, the connected 25-mission campaign and fresh-process persistence. Scripted balance witnesses are not human difficulty validation.
- `python3 tools/setup_android.py`: installed verified matching Godot Android templates, Temurin JDK 17, Android build tools 36.1.0/platform 36 and Gradle; repeated successfully with retained caches. Preserved normal TLS and checksum validation. Existing environment HTTPS proxy and system Java trust store were used.
- `bash tools/export_android.sh debug`: exit 0; APK built and rebuilt. APK signature verified (v2/v3), ARM64 and x86_64 included, ZIP alignment checked for 16 KB pages. APK metadata: `com.vladovidiu.dronekiller`, version `0.1.0`/1, min SDK 24, target SDK 36.
- `bash tools/export_android.sh unsigned`: exit 0; ARM64 AAB built and rebuilt. Google bundletool 1.18.2 accepted its structure. Inspected manifest: target API 36, landscape, Compatibility renderer, backup disabled, no declared Android permissions or debuggable application flag.
- Both archives passed ZIP integrity checks and contained the required gameplay/visual/UI JSON resources. Development tests/docs/tools were excluded. Every included native library's ELF LOAD alignment was at least 16 KB.
- Release export with absent signing variables stopped before building, as intended. **Signed release export was not run:** no publisher upload keystore/password was supplied or generated.
- Final editor headless import and `git diff --check` passed. Artifact hashes are recorded in the ignored `export/SHA256SUMS`.

Remaining release prerequisites: privately create/back up the upload key and generate the signed AAB; create/verify the Play Console account/app; supply publisher/support/privacy/audience/rating/listing information and approved artwork; test on real Android hardware and review Play's pre-launch report. No Play upload or publication occurred.

Native/physical Android rendering, touch, audio, performance and installation were not tested. ADB's polling attempts encounter the sandbox's read-only default home cache; this did not prevent APK/AAB export or validation. Godot's official Android template uses AGP 8.6.1 and emits its upstream warning that compile API 36 exceeds its tested API 35; the warning was retained, and builds completed successfully. No verification was suppressed.
