# M4 — optional rewarded advertising

> **0.1.2 update:** the exact Godot 4.6.3 Poing native bridge is now packaged and an offline export shim replaces the upstream editor installer. No AdMob account or publisher IDs exist yet, so live requests remain disabled. Test/production configuration and account prerequisites are documented in [ADS_SETUP.md](ADS_SETUP.md). The menu's information action grants no credits. Older M4 installation/debug-only notes below are historical; the earned-only accounting/consent contracts remain applicable.

## Implemented and deliberately not claimed

The existing offline game now has optional **Watch Ad / +50 WC** offers in Arsenal and campaign map, a provider abstraction, an editor-only callback simulator, a conditional Android test adapter, persistent installation-wide limits, and crash-recoverable reward accounting. Combat, campaign rewards, research prices and the existing M3 no-ad progression path are unchanged.

**No real advertisement has been verified on Android.** Godot 4.6.3 Android build presets and offline APK/AAB export tools are now available; see [Android build preparation](ANDROID_RELEASE.md). The exact Godot 4.6.3 native ads AAR is now checksum-verified and packaged. Android device validation and publisher AdMob consent-message configuration remain outstanding. The default provider is disabled; its menu action explains availability without granting a reward.

The native adapter now supports explicit Android test and production modes behind publisher-owned App ID, matching manifest metadata and reviewed privacy/audience gates. Test mode always uses the official Google rewarded unit. Current configuration remains disabled; no account or IDs were invented. A completed UMP flow is required before initialization or load.

## Selected integration and verified API

Selected **Poing Studios Godot AdMob v5.1.0**, MIT wrapper, pinned commit [`615974e9f66921a54e3c71c33db0856bdbf19d13`](https://github.com/poing-studios/godot-admob-plugin/tree/615974e9f66921a54e3c71c33db0856bdbf19d13), September 12, 2026. The maintained release advertises **Godot 4.5.0+**, which includes this project's engine series; Compatibility is retained because these are Android SDK overlays, not Godot rendering effects. This is source-level selection, not proof of a working 4.6.3 Android binary.

Inspected actual pinned upstream [rewarded documentation](https://github.com/poing-studios/godot-admob-plugin/blob/v5.1.0/docs/ad_formats/rewarded.md), [UMP documentation](https://github.com/poing-studios/godot-admob-plugin/blob/v5.1.0/docs/privacy/user_messaging_tools/get_started.md), [Android installation guide](https://github.com/poing-studios/godot-admob-plugin/blob/v5.1.0/platforms/android/README.md), GDScript listener/classes and native dependency configuration. [Source inventory and SHA-256 evidence](m4/plugin_sources.json) records exact files. `tools/check_admob_contract.py <upstream-checkout>` reproduces that source check. The public documentation host/API endpoint returned HTTP 403 here, so source/docs were read from a Git checkout of the release instead.

The pinned Android dependency is **`com.google.android.libraries.ads.mobile.sdk:ads-mobile-sdk:1.4.0`**, not an assumed classic `play-services-ads` version. Source uses UMP through `com.google.android.ump`; its resolved transitive version has not been measured with Gradle. Source compile SDK is 35, minimum SDK 24. Its build fallback Godot library is 4.7.0: **do not use that fallback AAR against 4.6.3**. Install/build the plugin's native template against the project's exact engine, per upstream instructions; published availability of the exact 4.6.3 template remains unverified. Store target-API requirements must be checked at publication; source compile SDK 35 does not establish current Google Play acceptance.

| Purpose | Actual v5.1.0 API used |
| --- | --- |
| Consent refresh | `UserMessagingPlatform.consent_information.update(parameters, success, failure)` |
| Consent decision | `get_consent_status()`: UNKNOWN=0, NOT_REQUIRED=1, REQUIRED=2, OBTAINED=3 |
| Required form | `get_is_consent_form_available()`, `UserMessagingPlatform.load_consent_form(success, failure)`, `ConsentForm.show(callback)` |
| Revisit privacy | `get_privacy_options_requirement_status()`, `show_privacy_options_form(callback)` |
| SDK configuration | `MobileAds.set_request_configuration(RequestConfiguration)` |
| SDK initialization | `MobileAds.initialize(OnInitializationCompleteListener)` |
| Load | `RewardedAdLoader.new().load(unit_id, AdRequest.new(), RewardedAdLoadCallback)` |
| Present | `RewardedAd.show(OnUserEarnedRewardListener)` |
| Earn | `listener.on_user_earned_reward(RewardedItem)` — **the only credit event** |
| Close / fail | `FullScreenContentCallback.on_ad_dismissed_full_screen_content` / `on_ad_failed_to_show_full_screen_content` — no credit |
| Disposal / verification context | `RewardedAd.destroy()`, `set_server_side_verification_options(ServerSideVerificationOptions)` |

This release **does not expose `ConsentInformation.can_request_ads()`**; no such method was invented. The adapter checks the pinned documented statuses after a fresh update/form flow. OBTAINED means a completed consent flow, not blanket permission for personalized advertising: the SDK must respect UMP signals. No custom forced-personalization flag is set. Ad loading/initialization is blocked on UNKNOWN, unresolved REQUIRED, update/form errors or an unreviewed audience.

The SDK `RewardedItem` exposes amount/type, **not an SSV transaction ID**. The sample item's amount does not override the game's 50 WC reward. Local random session identifiers are not described as Google-signed transaction identifiers. Where a provider supplies a transaction ID, the generic manager persists/deduplicates it. This native adapter supplies no fabricated network ID; it passes the local session token in SSV `custom_data` for later server correlation.

## Architecture and flow

- `scripts/ads/ad_adapter.gd`: load/show/earned/closed/failure/status signals; providers never write money.
- `poing_admob_adapter.gd`: optional, dynamically loaded pinned APIs; absent SDK files never cause unresolved scene dependencies. Configuration in `data/advertising.json` defaults disabled/unreviewed; explicit test mode uses the official rewarded test unit and production mode requires a publisher-owned unit. It refreshes consent before its first ad request per app process, initializes only after required consent handling, never preloads at startup and never requests an ad after privacy changes without another voluntary Watch action.
- `mock_ad_adapter.gd`: editor/debug desktop simulator. Both entry points and adapter installation require `OS.has_feature("editor") && OS.is_debug_build() && !OS.has_feature("android")`. A JSON flag, Android debug export or release custom feature cannot enable it through the game's normal paths.
- `RewardedAdsManager`: autoload after existing services, explicit menu context, one loading/presentation session at a time, earned callback ownership, real-time cooldown/timeout, optional pending-save retry.
- `rewarded_store.gd`: installation-wide validated version-1 write-ahead journal in `user://rewarded_ads.json`, independent of campaign reset.
- SaveManager: additive schema-v3 `ad_campaign_id` and `ad_receipts`. v1/v2/v3 money, research, ammunition, records and checkpoints remain intact. Existing saves receive no ad income merely by migration.
- `rewarded_ad_offer.gd`: reusable native controls; amount, remaining quota, loading/unavailable/saved status, retry after storage failure and UMP-required privacy options. Normal menu navigation remains available when ads are absent.

User presses Watch → availability/menu/foreground/quota/clock checks → persist unique deployment/campaign session → refresh required consent → initialize SDK once → load → recheck menu/foreground → persist showing → present → **earned callback** → durable journal intent/quota → atomically save campaign credit+receipt → finalize journal → refresh balance. Closing/failed load/failed show/timeout grants nothing. Presentation remains locked even if earning precedes dismissal and cooldown is configured to zero. Merely returning from background cannot award money.

Leaving a menu or backgrounding while loading invalidates that request; a late load cannot unexpectedly open a full-screen ad during combat. A native ad Activity may itself background Godot, so an already presented session remains owned and accepts its legitimate earned callback. A replacement campaign cannot receive another campaign's pending earnings.

## Reward amounts, limits and offline timing

`data/economy.json.rewarded_ads` is the single tuning source:

- `reward`: **50 WC** per valid earned callback, snapshotted at request.
- `daily_limit`: **5 successful rewards** per UTC day, at most 250 WC/day.
- `cooldown_seconds`: **60** after success; set 0 to disable. Failed/canceled ads do not consume slots or start cooldown.
- `clock_tolerance_seconds`: **300** for clock anomaly detection.
- `load_timeout_seconds`: **45**, including consent/SDK setup; timeout does not charge or block play.

Daily rollover uses UTC, not a timezone selection. In-session elapsed time comes from monotonic ticks, anchored once to wall UTC. Stored high-water time detects rollback across launches; mismatched wall/monotonic progression blocks new requests. Cooldown checks both monotonic elapsed time and persisted last-success time. New campaign does not reset the journal/quota. Successful earned events remain pending/claimable after storage errors and are not discarded solely because the clock changes after a legitimate presentation.

**These are best-effort local limits, not authoritative security.** A forward clock change across process restarts, clearing app data, restoring both files or modifying local storage can bypass local accounting. No trusted time endpoint, account service or SSV backend is configured. Corrupt ad history fails closed instead of resetting the allowance or using an older backup to reopen quota; offline campaign play remains available. Deleting all app data cannot be distinguished from a new install. Do not advertise local-only limits as fraud-proof.

The journal retains up to 4096 earnings (over two years at five/day). It then disables further requests rather than evicting idempotency evidence. A production backend/retention policy must replace that development safeguard before long-term monetized deployment.

## Crash/reward accounting

1. Record earned intent, campaign identity, amount, day, optional provider transaction ID and consumed daily slot in the ad journal.
2. Persist **credits + receipt ID in one existing campaign-save transaction**. Failure rolls both back; UI offers Retry reward save.
3. Mark the journal entry credited. If the app dies between steps 1–2, startup completes step 2. If it dies between steps 2–3, the existing receipt prevents another payment and startup finalizes the journal.

Dismissal never calls the credit operation. Duplicate callbacks, stale sessions, concurrent presentations, repeated provider IDs and restart/retry callbacks cannot pay twice through the implemented flow. A journal write failure does not credit unrecorded money; it retains a retryable in-memory event while the process lives. If storage never accepts that event and the process is killed, recovery cannot invent evidence of an unwritten SDK event. Independent corruption/rollback of local files cannot be made fully reliable with two unsigned files; production financial reconciliation needs a server.

## Editor testing

Normal startup keeps ads unavailable. To opt into **clearly labeled fake callbacks**:

```sh
godot --path . -- --rewarded-ads-simulate
```

In Godot's editor, set the same user argument in Project → Project Settings → Editor → Run → Main Run Args. Open Arsenal/campaign and press Watch. The dialog explicitly says **EDITOR SIMULATION — NOT A REAL AD**. Complete simulates the earned callback; Close simulates dismissal without a reward. These simulated rewards are persistent in that development save, so use isolated XDG data for testing, as the project's test runners do. This is not an AdMob SDK mock or evidence of real ads.

`tests/rewarded_ads.tscn` exercises success, cancellation, unavailable/load/show/consent failures, duplicate callbacks/provider IDs, concurrency before and after earning, background/resume, menu exit, timeout, daily limit/UTC rollover/clock anomalies, cooldown, campaign replacement, both storage boundaries, crash recovery and v1/v2/v3 saves. Fresh-process `--verify-ads` starts with a genuinely journaled, uncredited simulated event and verifies exactly one 50 WC credit.

`tests/admob_contract.tscn` runs the **actual conditional adapter control flow against test doubles of documented objects**: update/form denial blocks initialization, consent→config→init→load order, privacy re-entry, lifecycle failures and earned-only events. This verifies our boundary logic, not Google/native SDK behavior. `tests/rewarded_capture.tscn` uses the native display wrapper to verify actual touch buttons/dialogs and saved balances on four logical layouts.

See [M4 validation](m4/VALIDATION.md) for completed commands, counts and native frames. The existing full regression/earned-budget campaign still proves a viable **no-ad** path.

## Current Android installation and account setup

The runtime and exact native-template bridge are now installed by `python3 tools/setup_android.py` with a pinned SHA-256. The custom export plugin packages Android only and never downloads or mutates settings during editor startup. See [ADS_SETUP.md](ADS_SETUP.md) for provenance, public account identifiers, required owner configuration and test/production activation. Device consent/ad-flow validation and the publisher's privacy/audience decisions remain external prerequisites; signing alone does not activate ads.

## Privacy, children and Google Play release obligations

Publish a real, app-specific privacy policy and complete Play Data safety/Contains ads disclosures from the actual integrated SDKs and data collection. [Draft checklist/text](PRIVACY_POLICY_DRAFT.md) is unfinished publisher material, not a live policy. Explain that watching is optional, the exact 50 WC reward, the five/day limit, cooldown, and that no ad is needed to finish. No interstitial, app-open, surprise full-screen, paid currency or mandatory ad flow is implemented. War Credits are in-game progression currency; no cash redemption or currency-transfer mechanism exists.

Use an applicable Google-certified consent-management flow and configure current AdMob Privacy & messaging requirements for EEA/UK/Switzerland and relevant US states; UMP integration alone does not create the publisher's messages or legal disclosures. Keep a required privacy-options entry point accessible. Respect denial/limited-ad signals; never infer personalized consent from a local cached checkbox. Verify the current SDK/CMP version and policy requirements before release.

No age is inferred by the game and no false child-directed/underage tag is claimed for public users. Native test integration is gated to reviewed adult-only testing. If the publisher chooses a child-directed or mixed audience, implement an appropriate neutral age/audience flow, parental/consent requirements, child-directed and under-age request tags **before initialization**, suitable content rating and applicable Google Play Families/approved SDK policies. Do not enable this adapter for children by changing a boolean; leave ads unavailable until that design is implemented and validated.

Useful authoritative references (publisher must review current requirements): [Google rewarded ads](https://developers.google.com/admob/android/rewarded), [UMP/privacy](https://developers.google.com/admob/android/privacy), [test ads](https://developers.google.com/admob/android/test-ads), [rewarded inventory policy](https://support.google.com/admob/answer/7313578), [Google Play Families](https://support.google.com/googleplay/android-developer/answer/9893335), [Data safety](https://support.google.com/googleplay/android-developer/answer/10787469), [EU User Consent Policy](https://www.google.com/about/company/user-consent-policy/).

## Production authoritative accounting plan — not implemented

Use authenticated installation/player identity and a server-issued single-use session/nonce tied to reward configuration. Reserve/check five daily rewards and cooldown with **server UTC**, not a client date. Configure AdMob SSV and verify signatures/keys/query escaping per [Google SSV](https://developers.google.com/admob/android/ssv). Atomically deduplicate Google's `transaction_id`, validate ad unit/user/custom_data/reward payload, consume server quota and credit an authoritative ledger. The client should reconcile a server-confirmed reward receipt rather than credit once locally and again on SSV. Retries, reordered callbacks and multi-device requests must share the same unique constraints.

Do not trust client-reported rewards or treat a locally generated session token as proof of watching. Hashing an unsigned local file does not make it authoritative. Retain offline gameplay independently; reconcile online ad rewards when connectivity is available. No endpoint, credentials, production unit or backend account is invented in this project.
