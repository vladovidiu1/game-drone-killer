# DRONE KILLER: FRONTLINE — privacy policy draft

**Supplemental implementation-specific draft; not publisher approval.** The publisher supplied `https://vladovidiu1.github.io/game-drone-killer/privacy.html`; its current source is `docs/privacy.html`. The operator/contact below come from that page. Review remaining `[PUBLISHER: …]` fields and merge any needed details into the actual published policy. This draft does not replace the public page. The app keeps ads inactive until the outstanding publisher prerequisites are confirmed.

Effective date: **October 28, 2026 (current supplied public policy)**

Operator/controller: **Pintilie Vlad Ovidiu**; **[PUBLISHER: address where legally required]**

Privacy contact: **vlad.ovidiu.pintilie@gmail.com**

Policy URL: **https://vladovidiu1.github.io/game-drone-killer/privacy.html**

This policy covers **DRONE KILLER: FRONTLINE**, Android package `com.vladovidiu.dronekiller`. **[PUBLISHER: link the actual Google Play listing and identify the same developer as shown there.]**

## Game data stored on your device

The game has no player login, developer-operated cloud save service, game analytics service or developer-operated advertising server. It stores campaign progress, War Credits, research/upgrades, settings, active deployment/result identifiers, ad-reward receipts, and a local daily reward allowance on your device. Local receipts and randomly generated ad-session identifiers prevent duplicate credits and support recovery after an interrupted save; they are not an identity or an AdMob server-verified reward record.

These local records remain until replaced through normal play or deleted. Resetting the campaign replaces campaign progress but preserves independent settings and the installation-wide advertising allowance. Android's Clear storage or uninstall can remove local progress and settings. Android app backup is disabled in this build. **[PUBLISHER: review any changes to storage/backup before publishing; do not claim that deleting game storage deletes Google's separately processed information.]**

## Optional Google advertising and consent

The Android build includes **Poing Studios Godot AdMob 5.1.0**, **Google Mobile Ads Next-Gen SDK 1.4.0**, and **Google User Messaging Platform (UMP) 4.0.0**. No additional mediation partner is configured in this project. The Poing plugin is an integration layer; Google supplies advertising and consent services.

Advertising is optional. The campaign remains playable offline and requires no advertisement. When advertising is eligible and you select Watch Ad, the app refreshes UMP consent information, presents Google's consent form when required, checks the SDK's `canRequestAds()` result, and initializes/requests an ad only when permitted. Google may process information during the consent request even before any advertisement is requested. UMP stores consent information/options in application storage. A completed form does not imply permission for personalized advertising: the SDK applies the recorded choices.

Google's SDKs may process device and advertising identifiers (including Android advertising ID where available/permitted), IP address and approximate location derived from it, device/app information, advertising interactions, and diagnostic/performance information. Purposes include ad delivery, measurement, fraud prevention, security and applicable consent/legal requirements. The game does not intentionally send player names, email addresses or campaign contents to Google. A random per-request session token is supplied as ad verification custom data; it is not a server-side verification implementation or an account identifier.

**[PUBLISHER: confirm the current Google disclosures and actual configuration, collection/sharing, purposes, legal bases, recipients, international transfers and retention. Complete the Play Data safety declaration from those facts. Do not promise “no data collected” because this is a test-ad build.]**

References: [Google privacy policy](https://policies.google.com/privacy), [Google Mobile Ads Next-Gen data disclosure](https://developers.google.com/admob/android/next-gen/privacy/play-data-disclosure), [UMP for Android](https://developers.google.com/admob/android/privacy). These references supplement this app-specific policy.

## Rewards and choices

A successfully earned rewarded-ad callback grants exactly **50 War Credits**, saved locally. The current allowance is at most **five rewards per UTC day**, with a **60-second cooldown**. Opening or closing an advertisement, opening privacy choices, a loading/display error, or resuming the app does not grant credits. Advertising availability and the local allowance may be affected by connectivity, the SDK's decisions, clock changes or damaged local records; offline gameplay remains available.

When UMP requires privacy options, the campaign menu's **Ad privacy choices** action lets you reopen Google's form. A privacy error does not silently grant permission. The configured **Privacy policy** action opens this published policy in the device browser once the publisher supplies its real URL. You can also use applicable Android advertising controls. Declining advertising choices may change which advertisements are available; it does not prevent offline play.

## Audience

**[PUBLISHER: state the actual target ages and ensure they match Google Play Target audience and content, the game's design and AdMob configuration.]** The current integration is eligible only for an explicitly reviewed adult-only audience; it contains no verified age-screening flow for mixed audiences and must not be relabeled adult-only simply to enable ads. If the actual audience includes children or mixed ages, keep advertising off until the appropriate age handling, SDK tags, partner restrictions and Families obligations are implemented and reviewed.

## Rights, retention and contact

**[PUBLISHER: give the real process for access, correction/deletion, restriction, objection or consent withdrawal where applicable; describe retention and legal bases, applicable transfer safeguards, security measures and how to contact the appropriate supervisory authority.]** Contact the operator at the email above for app-related requests. Google has its own controls and privacy processes for information it processes; the operator must accurately explain those responsibilities and cannot promise to delete data it does not control.

## Policy changes

**[PUBLISHER: describe how material policy changes are communicated and maintain the effective date and actual published policy.]** Re-review this policy whenever SDKs, audience, advertising mode, mediation, analytics, cloud services or collection change.

## Publisher configuration before activation

Publish the completed policy, enter its real URL in `data/advertising.json`, publish applicable messages in **AdMob → Privacy & messaging**, and complete matching Play Console **Privacy policy**, **Target audience and content**, **Data safety** and **Contains ads** declarations. Confirm the actual age audience and perform the privacy review before setting activation flags. The actual supplied URL is configured. Age-audience/messaging/compliance fields have not been marked reviewed without confirmation.
