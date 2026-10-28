extends "res://scripts/ads/ad_adapter.gd"
# Optional dynamic boundary, verified against Poing v5.1.0 source/docs.
# No unresolved class dependencies when the plugin/native libraries are absent.
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

func configuration_issue() -> String:
 if not bool(config.get("enabled",false)) or str(config.get("mode","disabled")) == "disabled":
  return "Optional ads are not activated in this version. Offline play remains available."
 if config.get("mode") not in ["test","production"]:
  return "Advertising configuration is unavailable."
 if not bool(config.get("compliance_reviewed",false)) or config.get("audience") != "reviewed_adult_only" or not str(config.get("privacy_policy_url","")).begins_with("https://"):
  return "Advertising privacy setup is incomplete. Offline play remains available."
 var app_id := str(config.get("android_app_id",""))
 var pattern := RegEx.new()
 pattern.compile("^ca-app-pub-[0-9]{16}~[0-9]{10}$")
 if pattern.search(app_id) == null or app_id == "ca-app-pub-3940256099942544~3347511713":
  return "Advertising app registration is incomplete."
 if str(ProjectSettings.get_setting("admob/general/android/app_id","")) != app_id:
  return "Advertising build configuration is incomplete."
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
 return "Advertising service is unavailable. Offline play remains available."

func available() -> bool:
 # Explicit test/production modes require publisher-owned registration and fresh
 # UMP handling. No mock reward or sample-app consent bypass exists in exports.
 return configuration_issue().is_empty() and OS.has_feature("android") and ResourceLoader.exists(ROOT+"api/MobileAds.gd") and Engine.has_singleton("PoingGodotAdMob") and Engine.has_singleton("PoingGodotAdMobConsentInformation") and Engine.has_singleton("PoingGodotAdMobUserMessagingPlatform")

func rewarded_unit() -> String:
 return str(config.get("android_rewarded_id","")) if config.get("mode") == "production" else TEST_UNIT

func api(path: String) -> GDScript:
 return load(ROOT+path) as GDScript

func prepare(token: String) -> void:
 if not available():
  failed.emit(token,unavailable_reason())
  return
 current = token
 mobile = api("api/MobileAds.gd")
 ump = api("ump/api/UserMessagingPlatform.gd")
 if consent_checked:
  initialize_and_load(token)
  return
 status.emit("Checking advertising privacy choices…")
 var parameters: RefCounted = api("ump/core/ConsentRequestParameters.gd").new()
 parameters.set("tag_for_under_age_of_consent",false)
 # v5.1 exposes update/get_consent_status (not can_request_ads).
 ump.get("consent_information").call("update",parameters,func(): consent_updated(token),func(_error): fail_current(token,"Consent update unavailable; no ad requested."))

func consent_updated(token: String) -> void:
 if current != token:
  return
 var information: RefCounted = ump.get("consent_information")
 var consent_status := int(information.call("get_consent_status"))
 if consent_status in [1,3]: # ConsentStatus.NOT_REQUIRED / OBTAINED, exact pinned enum.
  consent_checked = true
  initialize_and_load(token)
 elif consent_status == 2 and bool(information.call("get_is_consent_form_available")):
  ump.call("load_consent_form",func(loaded_form):
   if current != token:
    return
   form = loaded_form
   form.call("show",func(error):
    if error != null:
     fail_current(token,"Consent form unavailable; no ad requested.")
    elif int(information.call("get_consent_status")) in [1,3]:
     consent_checked = true
     initialize_and_load(token)
    else:
     fail_current(token,"Advertising consent unavailable. Continue offline.")),func(_error): fail_current(token,"Consent form could not load. Continue offline."))
 else:
  fail_current(token,"Advertising consent unavailable. Continue offline.")

func initialize_and_load(token: String) -> void:
 if current != token:
  return
 if not initialized:
  var request_config: RefCounted = api("api/core/RequestConfiguration.gd").new()
  request_config.set("tag_for_child_directed_treatment",0)
  request_config.set("tag_for_under_age_of_consent",0)
  request_config.set("max_ad_content_rating","T")
  mobile.call("set_request_configuration",request_config)
  var listener: RefCounted = api("api/listeners/OnInitializationCompleteListener.gd").new()
  listener.set("on_initialization_complete",func(_sdk_status):
   initialized = true
   load_ad(token))
  callbacks.append(listener)
  mobile.call("initialize",listener)
 else:
  load_ad(token)

func load_ad(token: String) -> void:
 if current != token:
  return
 status.emit("Loading official Google test ad…" if config.get("mode") != "production" else "Loading optional rewarded ad…")
 var listener: RefCounted = api("api/listeners/RewardedAdLoadCallback.gd").new()
 listener.set("on_ad_failed_to_load",func(_error): fail_current(token,"Ad load failed. Continue offline."))
 listener.set("on_ad_loaded",func(loaded):
  if current != token:
   loaded.call("destroy")
   return
  ad = loaded
  ad_loaded.emit(token))
 callbacks.append(listener)
 api("api/RewardedAdLoader.gd").new().call("load",rewarded_unit(),api("api/core/AdRequest.gd").new(),listener)

func present(token: String) -> void:
 if current != token or ad == null:
  fail_current(token,"Ad unavailable for presentation.")
  return
 var content: RefCounted = api("api/listeners/FullScreenContentCallback.gd").new()
 content.set("on_ad_dismissed_full_screen_content",func(): closed.emit(token); discard_if_current.call_deferred(token))
 content.set("on_ad_failed_to_show_full_screen_content",func(_error): fail_current(token,"Ad presentation failed."))
 ad.set("full_screen_content_callback",content)
 var listener: RefCounted = api("api/listeners/OnUserEarnedRewardListener.gd").new()
 # RewardedItem has amount/type; it does NOT expose a server transaction ID.
 # The configured 50 WC reward is independent of the test item's sample amount.
 listener.set("on_user_earned_reward",func(_item): earned.emit(token,""))
 var verification: RefCounted = api("api/core/ServerSideVerificationOptions.gd").new()
 verification.set("custom_data",token)
 ad.call("set_server_side_verification_options",verification)
 callbacks.append(content)
 callbacks.append(listener)
 ad.call("show",listener)

func fail_current(token: String, reason: String) -> void:
 if current == token:
  failed.emit(token,reason)

func discard_if_current(token: String) -> void:
 if current == token:
  discard()

func discard() -> void:
 current = ""
 if ad != null:
  ad.call("destroy")
  ad = null
 form = null
 callbacks.clear()

func privacy_available() -> bool:
 return available() and ump != null and int(ump.get("consent_information").call("get_privacy_options_requirement_status")) == 2

func show_privacy_options() -> void:
 if not privacy_available() or not current.is_empty():
  return
 consent_checked = false
 ump.call("show_privacy_options_form",func(_error): status.emit("Privacy choices updated. Request another ad only if you choose."))
