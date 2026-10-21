extends Node
const SDK := preload("res://tests/fixtures/admob_contract_sdk.gd")
class Bridge extends "res://scripts/ads/poing_admob_adapter.gd":
 func available() -> bool:
  return true # Only this isolated test double overrides native/platform/release gating.
 func api(_path: String) -> GDScript:
  return preload("res://tests/fixtures/admob_contract_sdk.gd")
var checks := 0
var failures := 0
var errors := 0
var loaded := 0
var earned := 0
var closed := 0
var bridge: Node
const TOKEN := "0123456789abcdef0123456789abcdef"
func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error("FAIL: "+message)
func reset(status: int) -> void:
 if is_instance_valid(bridge):
  bridge.discard()
  remove_child(bridge)
  bridge.queue_free()
 SDK.consent_information = SDK.new()
 SDK.consent_status = status
 SDK.calls = []
 SDK.update_fails = false
 SDK.form_available = true
 SDK.form_fails = false
 SDK.form_obtains = false
 SDK.load_fails = false
 SDK.show_fails = false
 SDK.give_reward = true
 SDK.custom_token = ""
 errors = 0
 loaded = 0
 earned = 0
 closed = 0
 bridge = Bridge.new()
 add_child(bridge)
 bridge.failed.connect(func(_id: String, _reason: String): errors += 1)
 bridge.ad_loaded.connect(func(_id: String): loaded += 1)
 bridge.earned.connect(func(_id: String, transaction_id: String):
  earned += 1
  check(transaction_id.is_empty(),"RewardedItem is not misrepresented as SSV transaction ID"))
 bridge.closed.connect(func(_id: String): closed += 1)
func _ready() -> void:
 run.call_deferred()
func run() -> void:
 for status in [0,2]:
  reset(status)
  SDK.form_available = false
  bridge.prepare(TOKEN)
  check(errors == 1 and not SDK.calls.has("initialize") and not SDK.calls.has("ad_load"),"unknown/unresolved consent cannot initialize or load")
 reset(3)
 SDK.update_fails = true
 bridge.prepare(TOKEN)
 check(errors == 1 and not SDK.calls.has("initialize"),"launch consent refresh failure blocks even cached obtained consent")
 reset(2)
 SDK.form_fails = true
 bridge.prepare(TOKEN)
 check(errors == 1 and not SDK.calls.has("initialize"),"consent form load failure blocks SDK initialization")
 reset(2)
 bridge.prepare(TOKEN)
 check(errors == 1 and not SDK.calls.has("initialize"),"closing still-required consent form does not initialize advertising")
 reset(2)
 SDK.form_obtains = true
 bridge.prepare(TOKEN)
 check(loaded == 1 and errors == 0 and SDK.calls == ["consent_update","consent_form_load","consent_form_show","request_configuration","initialize","ad_load"],"consent → request config → initialization → load order")
 bridge.present(TOKEN)
 check(earned == 1 and closed == 1 and SDK.custom_token == TOKEN,"documented earned listener alone emits reward; SSV custom_data carries session token")
 await get_tree().process_frame
 check(SDK.calls.has("destroy"),"native rewarded object disposed after dismissal")
 reset(1)
 bridge.prepare(TOKEN)
 check(loaded == 1 and SDK.calls[0] == "consent_update" and not SDK.calls.has("consent_form_show"),"NOT_REQUIRED consent supports non-EEA availability without fabricating consent")
 check(bridge.privacy_available(),"UMP-required privacy options exposed")
 bridge.discard()
 bridge.show_privacy_options()
 check(SDK.calls.has("privacy_options") and not bridge.consent_checked,"privacy choices invalidate session consent readiness")
 bridge.prepare(TOKEN)
 check(SDK.calls.count("consent_update") == 2 and SDK.calls.count("initialize") == 1,"privacy return refreshes consent without duplicate SDK initialization")
 reset(3)
 SDK.load_fails = true
 bridge.prepare(TOKEN)
 check(errors == 1 and earned == 0 and loaded == 0,"native load failure emits no earned event")
 reset(3)
 SDK.show_fails = true
 bridge.prepare(TOKEN)
 bridge.present(TOKEN)
 check(errors == 1 and earned == 0 and closed == 0,"native presentation failure emits no earned event")
 reset(3)
 SDK.give_reward = false
 bridge.prepare(TOKEN)
 bridge.present(TOKEN)
 check(closed == 1 and earned == 0,"native dismissal alone has no reward")
 await get_tree().process_frame
 reset(3)
 SDK.give_reward = false
 bridge.prepare(TOKEN)
 bridge.present(TOKEN)
 var next_token := "fedcba9876543210fedcba9876543210"
 bridge.prepare(next_token)
 await get_tree().process_frame
 check(bridge.current == next_token and bridge.ad != null,"deferred cleanup from a dismissed session cannot destroy a newer ad")
 bridge.discard()
 bridge.queue_free()
 SDK.consent_information = null
 await get_tree().process_frame
 print("ADMOB BOUNDARY CONTRACT: %d checks, %d failures (test doubles; no native SDK)" % [checks,failures])
 get_tree().quit(1 if failures else 0)
