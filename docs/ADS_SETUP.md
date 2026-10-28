# Android rewarded ads — 0.1.5 / versionCode 6

The real Poing Studios Godot AdMob **5.1.0** bridge for **Godot 4.6.3** is integrated. Gradle resolves **Google Mobile Ads Next-Gen 1.4.0** and **UMP 4.0.0**. These are real Android libraries, not an editor mock. No actual advertisement has been displayed/verified on a physical Android device during this implementation.

## Current activation status

| Setting | Value |
| --- | --- |
| Package | `com.vladovidiu.dronekiller` |
| App ID, project setting and manifest | `ca-app-pub-3787873725289108~4168159841` |
| Stored production rewarded unit (never requested in TEST) | `ca-app-pub-3787873725289108/8579720139` |
| Mode | `test` |
| Actual TEST loader unit | `ca-app-pub-3940256099942544/5224354917` |
| `enabled` | `true` |
| `compliance_reviewed` | `true` |
| `audience` | `reviewed_adult_only` |
| `privacy_policy_url` | `https://vladovidiu1.github.io/game-drone-killer/privacy.html` |
| `privacy_messaging_configured` | `true` |

**TEST advertising is activated based on the publisher's confirmation.** On 2026-10-28, after the documented prerequisites and supported adult-only configuration were explained, the publisher stated “am confirmat tot” and requested the completed AAB. This confirms the documented supported audience, applicable published AdMob messages, public privacy policy and completed Play privacy/audience declarations for this configuration. The flags record the publisher's confirmation; they are not an independent audit of AdMob or Play Console. No console access or successful physical ad display is claimed.

The real policy URL was supplied by the publisher and its source is `docs/privacy.html`. Direct retrieval from this environment was blocked by the network proxy; publication/content confirmation is supplied by the publisher. No URL was invented. The stored production unit is never requested in TEST mode.

## Build, signing and remaining device checks

- No further local configuration prerequisite blocks TEST advertising. **UMP must still allow the request on the Android device**; missing/unresolved consent, unavailable server messages, network errors and a false `canRequestAds()` result still block initialization/load/display. Enabling the configuration does not bypass any of these runtime checks.
- This build uses **0.1.5 / versionCode 6**, above the previous repository build's 5. The package, save paths, reward/economy and existing signing setup are unchanged. If a higher code was uploaded independently, select a higher code before uploading.
- The cloud has **no publisher upload keystore or release signing credentials**. The delivered AAB is **unsigned and cannot be uploaded to Play as-is**. Sign it locally on Windows with the **same existing upload key** already used for the app; do not generate a replacement key. See [existing-key signing](ANDROID_RELEASE.md#sign-the-current-aab-with-the-existing-upload-key-windows).
- Upload the signed result to Internal Testing. Execute the physical Android checklist below. Google Play processing/pre-launch checks and an observed Test Ad remain device/console validation, not claims made by this build.
- Keep `mode="test"` and the official Google rewarded test unit. This is not a production-advertising release. A future change in audience, policy, messaging or SDK behavior requires renewed review; disable advertising if those prerequisites cease to hold.

## Actual runtime flow

An eligible voluntary Watch Ad request checks campaign/menu context, installation-wide quota and cooldown first. It refreshes consent information, displays the official required UMP form, and requires both a resolved UMP status and **the real `ConsentInformation.canRequestAds()` result** before SDK initialization, loading or presentation. UNKNOWN/unresolved REQUIRED, false permission, missing form and update/form errors fail closed. NOT_REQUIRED is supported only when the SDK also allows requests. No consent reset, forced geography or test-device consent bypass is shipped.

Pinned Poing 5.1.0 omits the `can_request_ads` wrapper method. The project extension in `addons/admob/gdscript/src/ump/api/ConsentInformation.gd` uses Godot 4.6.3's documented `JavaClassWrapper` plus built-in `AndroidRuntime.getApplicationContext()` to call **Google's actual** `com.google.android.ump.UserMessagingPlatform.getConsentInformation(context).canRequestAds()`. Missing JNI/runtime or exceptions return false. This does not replace UMP or approximate permission from a local flag.

The native Next-Gen bridge emits initialization-state ordinals **NOT_STARTED=0, INITIALIZING=1, COMPLETE=2, TIMED_OUT=3, FAILED=4**. The upstream GDScript classic two-state enum was corrected to match the measured 1.4.0 AAR. Only COMPLETE allows loading. Callbacks are connected before native UMP/form/initialization dispatch to avoid missing cached results.

The adapter logs `[RewardedAds]` events for configuration/plugin failures, consent update/required/incomplete/permission, SDK initialization, request/load/display start/failure, earned reward and dismissal. SDK errors include sanitized code/message; request/response objects, consent strings, advertising IDs and local receipt tokens are not dumped. Initialization/load timeouts produce a visible message. The short load timer does not interrupt a user reading an official consent form (separate bounded five-minute form wait). An ad loaded while the consent Activity pauses Godot waits for foreground resume before presentation; ordinary backgrounded loads are still canceled.

When UMP requires privacy options, **Ad privacy choices** reopens Google's official form. Returning invalidates consent readiness; another voluntary ad refreshes it. Errors remain visible, and withdrawal stays accessible independently of ad activation. A real configured HTTPS policy is linked from the offer. The publisher-supplied policy URL is available even while ad serving is gated.

Only the matching presented session's earned callback grants **50 War Credits**, saved immediately through the existing crash-recoverable journal and atomic campaign receipt. Duplicate native callbacks are rejected in the adapter and manager; dismissal/open/resume never grants credit. The existing **five rewards per UTC day**, **60-second cooldown**, cross-campaign quota and save recovery remain intact. Arsenal updates through the existing reward/balance signals. SSV is not implemented: a client session token is not a Google server transaction ID or an authoritative anti-fraud backend.

## Build and native verification

`python3 tools/setup_android.py` / `tools/setup_admob.py` install checksum-pinned exact 4.6.3 AARs. The project exporter adds App ID metadata, uses pinned Next-Gen dependencies, excludes conflicting classic `play-services-ads`/`ads-lite`, and pins browser 1.8.0 as before. It does not modify release keys or download SDKs from the editor.

- `./tests/run_checks.sh`: complete isolated-save regression, including rewarded quota/cooldown/duplicate/save/recovery and AdMob contract suites.
- `bash tools/export_android.sh unsigned`: actual ARM64 release AAB and bundletool structural validation.
- `python3 tools/validate_admob_aab.py export/drone-killer-unsigned.aab`: inspects the **actual AAB**, not a mock: package/version, non-debuggable/backup settings, App ID manifest metadata, native singleton registrations, network permissions, Google/UMP/Poing/AndroidRuntime DEX classes, `canRequestAds`/form/earned/load callback methods and signals, packaged TEST configuration, no signatures and ARM64 ABI. The script fails if a required component is absent.
- `addons/admob/PROVENANCE.json` records project extensions. `javap` inspection of the resolved SDK and Poing converter confirms real UMP methods and the initialization enum. These are structural/native API checks; JNI execution, consent server configuration, a visible test ad and device callback behavior still require Android hardware.

## Physical Android checklist

Use a build signed with the same existing key; preserve installed saves and do not uninstall just to test. After prerequisite configuration/activation and installing the Internal Testing update:

- Open campaign map/Arsenal, note balance and remaining daily allowance, tap **Watch Ad / +50 WC**. Check `adb logcat` for `[RewardedAds]` events; the advertisement must visibly indicate **Test Ad**. A button/dialog alone is not proof of a real ad.
- In a region where required, verify the real UMP form, completion, unresolved/error handling and **Ad privacy choices**. Where consent is not required, ensure requests still depend on `canRequestAds`. Do not reset real user consent to force a form; use Google's documented registered test-device workflow in a separate development build if region simulation is needed.
- Close/skip an advertisement without earning: balance and allowance must stay unchanged. Complete an ad: exactly **+50 WC**, once, with the Arsenal balance updated immediately.
- Restart: credited balance and receipt remain. Repeated/late earned callbacks are automated test cases; verify no extra reward on device close/resume/reopen.
- Complete five earned ads with at least 60 seconds between rewards: a sixth is unavailable until the next UTC day. A campaign reset must not reset the installation-wide allowance.
- Background/resume during consent and ads: no accidental cancellation of official consent UI, no ad over gameplay, no duplicate reward or credit just from resume. Test denied/unavailable/error cases.
- Disable network and restart: gameplay/campaign/saves remain usable; ads explain unavailability and grant nothing.

Do not report a real test ad as working until this device checklist has been executed and observed.

## Previous implementation validation (0.1.4)

On 2026-10-28 the complete `tests/run_checks.sh` runner passed, including the connected full-campaign/restart/comparison suites (260 + 31 + 11 checks). Reward accounting/restart passed 103 + 6 checks. The final focused AdMob contract run passed 35 checks, including real GDScript error/status types and fail-closed JNI availability; it uses SDK doubles for callbacks and does not display ads. The final unsigned 0.1.4/code 5 AAB passed bundletool and the native manifest/DEX/configuration validator. Existing signing-key file content was verified unchanged. `advertising-validation.json` is published with the GitHub AAB and explicitly records activation blockers and the absence of physical-device ad verification.

No display server was available during those checks, so graphical UI captures and physical Android consent/advertisement tests were not run. The runtime/gameplay suites use isolated save directories; no installed user saves were reset. Native class presence and methods do not establish that AdMob server-side messaging or the JNI/ad flow has executed successfully on a phone.

## Activation-build validation

For 0.1.5/code 6 only the confirmed activation flags, Android version and release documentation change. Runtime UMP, callback validation, gameplay and save code remain unchanged from the fully tested 0.1.4 implementation. Targeted isolated-save Godot import/startup, rewarded/restart, AdMob contract and menu/restart checks passed for the activated configuration, along with actual unsigned AAB export and native manifest/DEX/configuration validation. The native report confirms `advertising_enabled=true`, `advertising_mode="test"` and no configuration activation blockers; physical Android ad verification remains false until observed on a device.

Activated build results: 103 rewarded + 6 restart checks, 35 AdMob contract checks, 23 menu/audio + 3 restart checks passed without engine errors. The actual unsigned AAB passed bundletool and native DEX/manifest/configuration validation with TEST enabled and an empty configuration-blocker list. No release key was available; no upload signature or physical ad display is claimed.
