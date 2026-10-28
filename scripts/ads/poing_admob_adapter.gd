extends "res://scripts/ads/ad_adapter.gd"
# Pinned Poing 5.1.0 callbacks; Google's real UMP permission is queried via JNI.
const ROOT := "res://addons/admob/gdscript/src/"
const TEST_UNIT := "ca-app-pub-3940256099942544/5224354917"
var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/advertising.json"))
var mobile: GDScript
var ump: GDScript
var ad: RefCounted
var form: RefCounted
var callbacks: Array = []
var current := ""
var initialized := false
var consent_checked := false
var consent_form_open := false
var privacy_form_open := false
var consent_update_in_flight := false
var presenting := false
var reward_delivered := false
var stage := "idle"

func _ready() -> void:
 if not configuration_issue().is_empty():
  diagnostic("invalid_configuration",null,configuration_issue())
 elif not available():
  diagnostic("plugin_unavailable")

func configuration_issue() -> String:
 if not bool(config.get("enabled",false)) or str(config.get("mode","disabled")) == "disabled":
  return "Optional ads await publisher activation. Target audience and AdMob privacy messaging must be confirmed; offline play remains available."
 if config.get("mode") not in ["test","production"]:
  return "Advertising mode is invalid. Offline play remains available."
 if not str(config.get("privacy_policy_url","")).begins_with("https://"):
  return "The publisher has not configured a public HTTPS privacy policy. Offline play remains available."
 if config.get("audience") != "reviewed_adult_only":
  return "The actual target audience has not been confirmed or is not supported by this ad configuration. Offline play remains available."
 if not bool(config.get("privacy_messaging_configured",false)):
  return "The publisher must configure applicable AdMob Privacy & messaging forms. Offline play remains available."
 if not bool(config.get("compliance_reviewed",false)):
  return "The publisher's advertising privacy review is incomplete. Offline play remains available."
 var app_id := str(config.get("android_app_id",""))
 var pattern := RegEx.new()
 pattern.compile("^ca-app-pub-[0-9]{16}~[0-9]{10}$")
 if pattern.search(app_id) == null or app_id == "ca-app-pub-3940256099942544~3347511713":
  return "Advertising app registration is incomplete."
 if str(ProjectSettings.get_setting("admob/general/android/app_id","")) != app_id:
  return "Advertising build configuration does not match the registered app."
 if config.mode == "production":
  pattern.compile("^ca-app-pub-[0-9]{16}/[0-9]{10}$")
  var unit := str(config.get("android_rewarded_id",""))
  if pattern.search(unit) == null or unit.begins_with("ca-app-pub-3940256099942544/"):
   return "Rewarded advertising registration is incomplete."
 return ""

func unavailable_reason() -> String:
 var issue := configuration_issue()
 if not issue.is_empty():
  return issue
 if not OS.has_feature("android"):
  return "Optional ads are available on Android only."
 return "The Android advertising/consent plugin is unavailable. Offline play remains available."

func available() -> bool:
 return configuration_issue().is_empty() and OS.has_feature("android") and ResourceLoader.exists(ROOT+"api/MobileAds.gd") and Engine.has_singleton("AndroidRuntime") and Engine.has_singleton("PoingGodotAdMob") and Engine.has_singleton("PoingGodotAdMobRewardedAd") and Engine.has_singleton("PoingGodotAdMobConsentInformation") and Engine.has_singleton("PoingGodotAdMobUserMessagingPlatform")

func rewarded_unit() -> String:
 return str(config.get("android_rewarded_id","")) if config.get("mode") == "production" else TEST_UNIT

func api(path: String) -> GDScript:
 return load(ROOT+path) as GDScript

func prepare(token: String) -> void:
 if not available():
  diagnostic("invalid_configuration" if not configuration_issue().is_empty() else "plugin_unavailable")
  failed.emit(token,unavailable_reason())
  return
 if privacy_form_open or consent_form_open or consent_update_in_flight:
  failed.emit(token,"A privacy request is still open. Complete it, then try again.")
  return
 current = token
 presenting = false
 reward_delivered = false
 consent_checked = false
 mobile = api("api/MobileAds.gd")
 ump = api("ump/api/UserMessagingPlatform.gd")
 stage = "consent_update"
 diagnostic("consent_update_started")
 status.emit("Checking advertising privacy choices…")
 var parameters: RefCounted = api("ump/core/ConsentRequestParameters.gd").new()
 # Reached only after reviewed adult-only configuration; never infer age from UMP.
 parameters.set("tag_for_under_age_of_consent",false)
 consent_update_in_flight = true
 ump.get("consent_information").call("update",parameters,func():
  consent_update_in_flight = false
  consent_updated(token),func(error):
  consent_update_in_flight = false
  fail_current(token,"Consent update failed; no ad requested. Check your connection and try again.","consent_update_failed",error))

func consent_updated(token: String) -> void:
 if current != token:
  return
 var information: RefCounted = ump.get("consent_information")
 var consent_status := int(information.call("get_consent_status"))
 if consent_status in [1,3]:
  diagnostic("consent_not_required" if consent_status == 1 else "consent_completed")
  finish_consent(token)
 elif consent_status == 2 and bool(information.call("get_is_consent_form_available")):
  stage = "consent_form"
  diagnostic("consent_required")
  status.emit("Complete Google's advertising privacy form to continue.")
  ump.call("load_consent_form",func(loaded_form):
   if current != token:
    return
   form = loaded_form
   consent_form_open = true
   status.emit("Advertising privacy form is open…")
   form.call("show",func(error):
    consent_form_open = false
    if current != token:
     status.emit("Advertising privacy form closed. Request another ad only if you choose.")
     return
    if error != null:
     fail_current(token,"Consent form failed; no ad requested. You can continue offline.","consent_form_failed",error)
    else:
     finish_consent(token)),func(error): fail_current(token,"Consent form could not load. Check AdMob messaging setup or try again later.","consent_form_load_failed",error))
 else:
  fail_current(token,"Advertising privacy choices are unresolved. No ad requested; continue offline.","consent_not_completed")

func consent_permission() -> bool:
 return ump != null and bool(ump.get("consent_information").call("can_request_ads"))

func finish_consent(token: String) -> void:
 if current != token:
  return
 # OBTAINED alone does not authorize ads; the SDK's real canRequestAds is decisive.
 var consent_status := int(ump.get("consent_information").call("get_consent_status"))
 if consent_status not in [1,3] or not consent_permission():
  fail_current(token,"Google UMP does not currently permit an ad request. Continue offline or review privacy choices.","consent_not_completed")
  return
 consent_checked = true
 diagnostic("consent_ads_permitted")
 initialize_and_load(token)

func initialize_and_load(token: String) -> void:
 if current != token:
  return
 if not consent_checked or not consent_permission():
  fail_current(token,"Advertising privacy permission changed; no ad requested.","consent_not_completed")
  return
 if not initialized:
  stage = "sdk_initialization"
  diagnostic("sdk_initialization_started")
  status.emit("Starting Android advertising service…")
  var request_config: RefCounted = api("api/core/RequestConfiguration.gd").new()
  request_config.set("tag_for_child_directed_treatment",0)
  request_config.set("tag_for_under_age_of_consent",0)
  request_config.set("max_ad_content_rating","T")
  mobile.call("set_request_configuration",request_config)
  var listener: RefCounted = api("api/listeners/OnInitializationCompleteListener.gd").new()
  listener.set("on_initialization_complete",func(sdk_status):
   if current != token:
    return
   if not sdk_ready(sdk_status):
    fail_current(token,"Android advertising initialization did not become ready. Try again later.","sdk_initialization_failed")
    return
   initialized = true
   diagnostic("sdk_initialized")
   load_ad(token))
  callbacks.append(listener)
  mobile.call("initialize",listener)
 else:
  load_ad(token)

func sdk_ready(sdk_status: Variant) -> bool:
 if sdk_status == null:
  return false
 var entries: Variant = sdk_status.get("adapter_status_map")
 if not entries is Dictionary:
  return false
 for entry in entries.values():
  if entry != null and int(entry.get("initialization_state")) == 2:
   return true
 return false

func load_ad(token: String) -> void:
 if current != token:
  return
 if not consent_permission():
  fail_current(token,"Google UMP no longer permits an ad request.","consent_not_completed")
  return
 stage = "ad_load"
 diagnostic("ad_request_started",null,"official_google_test_unit" if config.get("mode") == "test" else "publisher_unit")
 status.emit("Loading official Google test ad…" if config.get("mode") == "test" else "Loading optional rewarded ad…")
 var listener: RefCounted = api("api/listeners/RewardedAdLoadCallback.gd").new()
 listener.set("on_ad_failed_to_load",func(error): fail_current(token,"Ad unavailable. Check your connection or try again later. "+error_summary(error),"ad_load_failed",error))
 listener.set("on_ad_loaded",func(loaded):
  if current != token:
   loaded.call("destroy")
   return
  ad = loaded
  stage = "ad_ready"
  diagnostic("ad_loaded")
  ad_loaded.emit(token))
 callbacks.append(listener)
 api("api/RewardedAdLoader.gd").new().call("load",rewarded_unit(),api("api/core/AdRequest.gd").new(),listener)

func present(token: String) -> void:
 if current != token or ad == null or not consent_checked or not consent_permission():
  fail_current(token,"Ad unavailable or privacy permission changed. No reward granted.","ad_display_failed")
  return
 var content: RefCounted = api("api/listeners/FullScreenContentCallback.gd").new()
 content.set("on_ad_showed_full_screen_content",func():
  if current == token:
   diagnostic("ad_display_started"))
 content.set("on_ad_dismissed_full_screen_content",func():
  if current == token:
   presenting = false
   diagnostic("ad_dismissed")
   closed.emit(token)
   discard_if_current.call_deferred(token))
 content.set("on_ad_failed_to_show_full_screen_content",func(error): fail_current(token,"Ad could not be displayed. No reward granted. "+error_summary(error),"ad_display_failed",error))
 ad.set("full_screen_content_callback",content)
 var listener: RefCounted = api("api/listeners/OnUserEarnedRewardListener.gd").new()
 # Google's sample item amount is not our economy and is not an SSV transaction ID.
 listener.set("on_user_earned_reward",func(_item):
  if current != token or not presenting or reward_delivered:
   return
  reward_delivered = true
  diagnostic("reward_earned",null,"50 War Credits; pending manager validation/save")
  earned.emit(token,""))
 var verification: RefCounted = api("api/core/ServerSideVerificationOptions.gd").new()
 verification.set("custom_data",token)
 ad.call("set_server_side_verification_options",verification)
 callbacks.append(content)
 callbacks.append(listener)
 stage = "ad_show"
 presenting = true
 diagnostic("ad_display_requested")
 ad.call("show",listener)

func fail_current(token: String, reason: String, event := "ad_flow_failed", error: Variant = null) -> void:
 if current == token:
  diagnostic(event,error)
  failed.emit(token,reason)

func timeout_reason() -> String:
 diagnostic("sdk_initialization_failed" if stage == "sdk_initialization" else "ad_flow_timeout")
 return "Advertising step timed out (%s). No reward granted; offline play remains available." % stage

func discard_if_current(token: String) -> void:
 if current == token:
  discard()

func discard() -> void:
 current = ""
 presenting = false
 reward_delivered = false
 stage = "idle"
 if ad != null:
  ad.call("destroy")
  ad = null
 # An official UMP form cannot be force-dismissed via this plugin. Retain its
 # native callback until dismissal and ignore the now-stale request token.
 if not consent_form_open:
  form = null
 callbacks.clear()

func consent_ui_active() -> bool:
 return consent_form_open or privacy_form_open

func request_stage() -> String:
 return stage

func privacy_available() -> bool:
 # Keep a privacy entry point on eligible Android installs even before Watch Ad.
 # A previously required form also remains accessible if activation is blocked.
 return available() or (ump != null and int(ump.get("consent_information").call("get_privacy_options_requirement_status")) == 2)

func privacy_policy_url() -> String:
 var url := str(config.get("privacy_policy_url",""))
 return url if url.begins_with("https://") else ""

func show_privacy_options() -> void:
 if not privacy_available() or not current.is_empty() or privacy_form_open or consent_form_open or consent_update_in_flight:
  return
 if ump == null:
  ump = api("ump/api/UserMessagingPlatform.gd")
 consent_checked = false
 privacy_form_open = true
 status.emit("Checking advertising privacy options…")
 # If publisher activation was revoked after a required form was obtained,
 # preserve access to that form rather than requiring advertising to be enabled.
 if not available():
  present_privacy_form()
  return
 var parameters: RefCounted = api("ump/core/ConsentRequestParameters.gd").new()
 parameters.set("tag_for_under_age_of_consent",false)
 consent_update_in_flight = true
 ump.get("consent_information").call("update",parameters,func():
  consent_update_in_flight = false
  present_privacy_form(),func(error):
  consent_update_in_flight = false
  privacy_options_finished(error))

func present_privacy_form() -> void:
 if int(ump.get("consent_information").call("get_privacy_options_requirement_status")) != 2:
  privacy_form_open = false
  diagnostic("privacy_options_not_required")
  status.emit("Google reports no required privacy options form for this session. No ad requested.")
  return
 diagnostic("privacy_options_opened")
 status.emit("Advertising privacy choices are open…")
 ump.call("show_privacy_options_form",privacy_options_finished)

func privacy_options_finished(error: Variant) -> void:
 privacy_form_open = false
 if error != null:
  diagnostic("privacy_options_failed",error)
  status.emit("Privacy choices could not open. "+error_summary(error)+" Try again later.")
 else:
  diagnostic("privacy_options_closed")
  status.emit("Privacy choices updated. No ad requested; choose Watch Ad to check eligibility again.")

func error_summary(error: Variant) -> String:
 if error == null:
  return "SDK error details unavailable."
 var code: Variant = error.get("error_code") if error is Dictionary and error.has("error_code") else error.get("code")
 if error is Object and error.get("error_code") != null:
  code = error.get("error_code")
 var text: Variant = error.get("message")
 return "SDK error %s: %s" % [str(code) if code != null else "unknown",safe_text(str(text) if text != null else "No message supplied")]

func safe_text(text: String) -> String:
 # Never dump response_info, request IDs, consent strings, tokens or whole SDK objects.
 var expression := RegEx.new()
 for pattern in ["https?://[^ ]+","[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+", "[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+", "[A-Fa-f0-9-]{24,}"]:
  expression.compile(pattern)
  text = expression.sub(text,"[redacted]",true)
 return text.replace("\n"," ").replace("\r"," ").left(240)

func diagnostic(event: String, error: Variant = null, detail := "") -> void:
 print("[RewardedAds] ",event," | ",error_summary(error) if error != null else safe_text(detail))
