# Android test build and Google Play preparation

Package: `com.vladovidiu.dronekiller` (confirmed by the publisher). Version: `0.1.0`, Android version code `1`. Godot: standard 4.6.3 stable, Compatibility renderer. Minimum Android API 24 (Android 7), target/compile API 36. Offline gameplay has no account, backend, advertising SDK, or purchase requirement. The optional advertising provider remains disabled; this build must not be described as monetized with real ads.

## Build in the cloud environment

Use the existing checkout in `/workspace/game-drone-killer`; no extra Git worktree is needed. Linux x86_64 needs Python 3.12+, Bash, Godot 4.6.3, GNU timeout and ripgrep. The setup helper installs Temurin JDK 17, Android command-line tools/build tools/platform 36 and matching Godot export templates under `/workspace/toolchains`, outside Git. It verifies downloaded artifacts, accepts the Android SDK licenses for this build environment, and configures the environment's existing HTTPS proxy with normal TLS verification. Gradle uses four workers. No runtime or source generators should be rerun for setup.

```sh
cd /workspace/game-drone-killer
python3 tools/setup_android.py
bash tools/export_android.sh debug
bash tools/export_android.sh unsigned
./tests/run_checks.sh
```

`export/drone-killer-test.apk` is debug-signed, includes ARM64 and x86_64, and can be installed directly on a compatible Android device. Enable installation from the browser/file manager only when prompted for this APK. Alternatively, with Android platform-tools and USB debugging on your computer:

```sh
adb install -r drone-killer-test.apk
```

The unsigned AAB is a build-validation artifact, **not uploadable to Google Play**. The Play presets use ARM64. APK/AAB files, Gradle outputs, SDK caches and signing keys are excluded from Git. Download artifacts from the prepared environment before discarding it. Keep the debug key if you want later debug APKs to update the same installation; a different key requires uninstalling first, which can remove saves. Production signing will also differ from this debug APK.

## Create the upload key and signed AAB

For this new Play application, create an upload key locally in a private backed-up directory, not inside the repository. Use a password manager and keep a separate protected backup. Do not send the key or password in chat, commit them, or reuse the debug key.

```sh
keytool -genkeypair -v -keystore /private/path/drone-killer-upload.jks \
  -alias upload -keyalg RSA -keysize 3072 -validity 10000
```

This prompts for the password and publisher identity. Use the same store/key password for Godot's export support. In a trusted local shell or secret-capable CI, provide `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER=upload` and `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD` without putting passwords in shell history. Then:

```sh
bash tools/export_android.sh release
```

`export/drone-killer.aab` is the signed upload artifact. The helper fails early when signing variables are missing. No production key was generated during onboarding. Verify the signed AAB with `jarsigner -verify -verbose -certs export/drone-killer.aab` and confirm that its certificate matches your backed-up upload key. Enroll in Play App Signing in the Console; Google manages the distribution key and this key authenticates uploads. Increment `version/code` in all presets for every subsequent Play upload.

## Primii pași în Play Console

1. Creează contul la <https://play.google.com/console/signup>, alege tipul corect (personal/organizație), achită taxa afișată și finalizează verificările de identitate/contact/dispozitiv cerute de Google. Pentru APK-ul instalat direct nu ai nevoie de acest cont.
2. Creează aplicația ca **joc**, setează numele, limba și distribuția gratuită sau plătită. Păstrează identificatorul `com.vladovidiu.dronekiller`; nu îl schimba după prima publicare. Pentru un prim test prin Play folosește **Internal testing**, nu producția.
3. Activează Play App Signing și încarcă AAB-ul **semnat**, nu APK-ul de debug sau AAB-ul unsigned. Adaugă testerii și distribuie linkul de înscriere furnizat de Console.
4. Completează fișa magazinului: descriere, icon 512×512, feature graphic 1024×500, capturi reale pe Android, email de suport și o politică de confidențialitate publică HTTPS, adaptată versiunii distribuite. `docs/PRIVACY_POLICY_DRAFT.md` este doar un draft și nu este o politică publicată.
5. Completează App access, Data safety, Content rating/IARC, publicul țintă și declarația Contains ads conform binarului real. Acest build nu conține SDK-ul de reclame; nu declara colectări sau funcții pe baza unei integrări viitoare. Nu inventa identitatea editorului, ratingul sau grupa de vârstă. Verifică licențele și drepturile asupra tuturor materialelor înainte de lansare.
6. Urmează cerințele de testare și eligibilitate afișate pentru contul tău, inclusiv testarea închisă dacă este cerută înainte de accesul la producție. Verifică cerința curentă de target API la data trimiterii: <https://support.google.com/googleplay/android-developer/answer/11926878>. API 36 este configurația acestui build; acceptarea finală aparține Play Console.

## Device and release gate

The headless suites exercise real game logic and saved-state transactions; they do not establish physical touch, audio, GPU correctness, performance or store acceptance. Before production, install on real ARM64 Android hardware and check launch/new campaign, tutorial and skip, independent aim/FIRE fingers, safe areas, pause/background/resume, full victory/defeat/retry, saves after restart and offline startup. Follow `ANDROID_VISUAL_TEST_CHECKLIST.md`. Inspect Play's pre-launch report and test the Play-delivered build as well as the sideloaded APK.

Do not enable the optional AdMob adapter for release merely to satisfy store setup. Real monetization needs its separate SDK, consent/privacy/audience and device validation work documented in `REWARDED_ADS.md`.
