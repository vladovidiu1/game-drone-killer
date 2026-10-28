extends RefCounted
# Test double for documented Poing objects; never a claim of native SDK execution.
static var consent_information: RefCounted
static var consent_status := 0
static var update_fails := false
static var form_available := true
static var form_fails := false
static var form_obtains := false
static var load_fails := false
static var show_fails := false
static var give_reward := true
static var permission := true
static var initialization_ready := true
static var privacy_fails := false
static var duplicate_reward := false
static var calls: Array = []
static var custom_token := ""
static var loaded_unit := ""
var is_form := false
var tag_for_under_age_of_consent := false
var tag_for_child_directed_treatment := 0
var max_ad_content_rating := ""
var custom_data := ""
var on_initialization_complete: Callable
var on_ad_failed_to_load: Callable
var on_ad_loaded: Callable
var on_ad_dismissed_full_screen_content: Callable
var on_ad_failed_to_show_full_screen_content: Callable
var on_user_earned_reward: Callable
var full_screen_content_callback: RefCounted
var on_ad_showed_full_screen_content: Callable
var adapter_status_map: Dictionary = {}
var initialization_state := 2

func update(_parameters: RefCounted, success: Callable, failure: Callable) -> void:
 calls.append("consent_update")
 failure.call({}) if update_fails else success.call()
func get_consent_status() -> int:
 return consent_status
func can_request_ads() -> bool:
 return permission
func get_is_consent_form_available() -> bool:
 return form_available
func get_privacy_options_requirement_status() -> int:
 return 2
static func load_consent_form(success: Callable, failure: Callable) -> void:
 calls.append("consent_form_load")
 if form_fails:
  failure.call({})
 else:
  var form: RefCounted = load("res://tests/fixtures/admob_contract_sdk.gd").new()
  form.is_form = true
  success.call(form)
static func set_request_configuration(_config: RefCounted) -> void:
 calls.append("request_configuration")
static func initialize(listener: RefCounted) -> void:
 calls.append("initialize")
 var status: RefCounted = load("res://tests/fixtures/admob_contract_sdk.gd").new()
 var entry: RefCounted = load("res://tests/fixtures/admob_contract_sdk.gd").new()
 entry.initialization_state = 2 if initialization_ready else 4
 status.adapter_status_map = {"google":entry}
 listener.on_initialization_complete.call(status)
func load(_unit: String, _request: RefCounted, callback: RefCounted) -> void:
 loaded_unit = _unit
 calls.append("ad_load")
 if load_fails:
  callback.on_ad_failed_to_load.call({})
 else:
  callback.on_ad_loaded.call(load("res://tests/fixtures/admob_contract_sdk.gd").new())
func show(listener: Variant) -> void:
 if is_form:
  calls.append("consent_form_show")
  if form_obtains:
   consent_status = 3
  listener.call(null)
 else:
  calls.append("ad_show")
  if show_fails:
   full_screen_content_callback.on_ad_failed_to_show_full_screen_content.call({})
  else:
   full_screen_content_callback.on_ad_showed_full_screen_content.call()
   if give_reward:
    on_user_earned_reward = listener.on_user_earned_reward
    on_user_earned_reward.call({"amount":99999,"type":"sample"})
    if duplicate_reward:
     on_user_earned_reward.call({"amount":99999,"type":"sample"})
   full_screen_content_callback.on_ad_dismissed_full_screen_content.call()
func set_server_side_verification_options(options: RefCounted) -> void:
 custom_token = options.custom_data
func destroy() -> void:
 calls.append("destroy")
static func show_privacy_options_form(callback: Callable) -> void:
 calls.append("privacy_options")
 callback.call({"error_code":3,"message":"Privacy form failed"} if privacy_fails else null)
