# Android rewarded ads — 0.1.4 / versionCode 5

The real Poing Studios Godot AdMob **5.1.0** bridge for **Godot 4.6.3** is integrated. Gradle resolves **Google Mobile Ads Next-Gen 1.4.0** and **UMP 4.0.0**. These are real Android libraries, not an editor mock. No actual advertisement has been displayed/verified on a physical Android device during this implementation.

## Current activation status

| Setting | Value |
| --- | --- |
| Package | `com.vladovidiu.dronekiller` |
| App ID, project setting and manifest | `ca-app-pub-3787873725289108~4168159841` |
| Stored production rewarded unit (never requested in TEST) | `ca-app-pub-3787873725289108/8579720139` |
| Mode | `test` |
| Actual TEST loader unit | `ca-app-pub-3940256099942544/5224354917` |
| `enabled` | `false` |
| `compliance_reviewed` | `false` |
| `audience` | `unreviewed` |
| `privacy_policy_url` | `https://vladovidiu1.github.io/game-drone-killer/privacy.html` |
| `privacy_messaging_configured` | `false` |

**Test-ad serving remains blocked by unverified publisher privacy/audience prerequisites.** Signing or installing the AAB does not activate advertising. The policy URL was supplied by the publisher and its source was inspected in `docs/privacy.html`; direct public-page retrieval was blocked by this environment (HTTP tunnel 403), so public reachability still needs a browser check. No adult audience or privacy review has been invented. The application remains playable offline, and the available Ad information action explains the blocker without granting a reward.

## Minimum external actions

1. Open the supplied policy URL in a private browser window and confirm it is publicly accessible without login. The configured policy source `docs/privacy.html` identifies Pintilie Vlad Ovidiu and the provided contact email. The app-specific supplemental draft in [PRIVACY_POLICY_DRAFT.md](PRIVACY_POLICY_DRAFT.md) records actual SDK/storage/reward details for publisher review; a draft alone is not a reviewed public policy.
2. Confirm the **actual target age audience** from Play Console → **App content → Target audience and content**. This build supports reviewed adult-only advertising; it does not implement mixed/child audience handling. A content rating is not an audience declaration. Do not select adult-only unless it matches the app and the real declaration.
3. In **AdMob → Privacy & messaging**, select this application, supply the real policy URL, configure and publish applicable messages (European regulations for EEA/UK/Switzerland distribution, US-state regulations and other applicable regions). IDs alone do not create consent messages. Server-side form delivery still must be tested; a local flag cannot verify the console.
4. Complete/update Play Console **Privacy policy**, **Contains ads**, **Data safety**, and target audience declarations against the actual SDKs/build. Google's SDK can process information during consent even without displaying an ad; “test” does not mean “no collection.” No extra mediation partner or game analytics backend is configured.
5. After those facts are confirmed/reviewed, configure `data/advertising.json`: real `privacy_policy_url`, the supported confirmed `audience="reviewed_adult_only"`, `privacy_messaging_configured=true`, `compliance_reviewed=true`, `enabled=true`. **Keep `mode="test"`** and both supplied IDs unchanged. The URL is configured, but activation flags remain false/unreviewed while age-audience and messaging/review facts are unconfirmed. Activation requires a rebuilt AAB; if the real audience includes children/mixed ages, additional implementation/review is required instead.
6. Sign the unsigned AAB with the existing upload key, upload to Internal Testing using a versionCode above every code already uploaded, and perform the physical checklist below. This version uses code **5**, above the previous repository build's **4**. If a higher code was uploaded independently, increase it before uploading.

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

## Evidence for this build

On 2026-10-28 the complete `tests/run_checks.sh` runner passed, including the connected full-campaign/restart/comparison suites (260 + 31 + 11 checks). Reward accounting/restart passed 103 + 6 checks. The final focused AdMob contract run passed 35 checks, including real GDScript error/status types and fail-closed JNI availability; it uses SDK doubles for callbacks and does not display ads. The final unsigned 0.1.4/code 5 AAB passed bundletool and the native manifest/DEX/configuration validator. Existing signing-key file content was verified unchanged. `advertising-validation.json` is published with the GitHub AAB and explicitly records activation blockers and the absence of physical-device ad verification.

No display server is available in this cloud session, so graphical UI captures and physical Android consent/advertisement tests were not run. The runtime/gameplay suites use isolated save directories; no installed user saves were reset. Native class presence and methods do not establish that AdMob server-side messaging or the JNI/ad flow has executed successfully on a phone.
