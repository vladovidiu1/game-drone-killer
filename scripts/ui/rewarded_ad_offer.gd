extends VBoxContainer
const UI := preload("res://scripts/ui/ui_kit.gd")
var compact := false
var watch: Button
var details: Label
var retry: Button
var privacy: Button
var elapsed := 0.0

func _ready() -> void:
 add_theme_constant_override("separation",6)
 var row: BoxContainer = VBoxContainer.new() if compact else HBoxContainer.new()
 row.add_theme_constant_override("separation",10)
 add_child(row)
 watch = UI.button("",_watch,Vector2(0 if compact else 260,54))
 watch.add_theme_font_size_override("font_size",17)
 row.add_child(watch)
 details = UI.label("",14,UI.MUTED)
 details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 details.size_flags_vertical = Control.SIZE_SHRINK_CENTER
 row.add_child(details)
 retry = UI.button("Retry reward save",RewardedAdsManager.retry_reward_save,Vector2(0,54))
 retry.add_theme_font_size_override("font_size",16)
 add_child(retry)
 privacy = UI.button("Ad privacy choices",_privacy,Vector2(0,54))
 privacy.add_theme_font_size_override("font_size",16)
 add_child(privacy)
 RewardedAdsManager.changed.connect(refresh)
 refresh()

func _privacy() -> void:
 RewardedAdsManager.adapter.show_privacy_options()

func refresh() -> void:
 var offer := RewardedAdsManager.offer()
 watch.text = "Ad information" if offer.setup_required else "Watch Ad  /  +%d WC" % int(offer.amount)
 watch.disabled = not bool(offer.enabled) and not bool(offer.setup_required)
 var status := str(offer.message)
 if phase_needs_reason(offer):
  status += "\n"+str(offer.reason)
 details.text = "Optional ads are not active in this version. Tap Ad information. Offline progress is unchanged." if offer.setup_required else "%d / %d rewards remaining today (UTC)\n%s" % [int(offer.remaining),int(offer.limit),status]
 retry.visible = str(offer.phase) == "pending"
 privacy.visible = RewardedAdsManager.adapter.privacy_available()

func phase_needs_reason(offer: Dictionary) -> bool:
 return not str(offer.reason).is_empty() and str(offer.reason) != str(offer.message) and str(offer.phase) == "idle"

func _process(delta: float) -> void:
 elapsed += delta
 if elapsed >= 1.0:
  elapsed = 0.0
  refresh()

func _watch() -> void:
 var offer := RewardedAdsManager.offer()
 if offer.enabled:
  RewardedAdsManager.request()
 elif offer.setup_required:
  var dialog := AcceptDialog.new()
  dialog.name = "AdsInformation"
  dialog.title = "Optional ads"
  dialog.dialog_text = "Optional rewarded ads are not active in this version.\nYou can continue the whole campaign offline.\nOpening this information screen does not grant War Credits."
  add_child(dialog)
  var close := dialog.get_ok_button()
  close.set_script(preload("res://scripts/ui/touch_button.gd"))
  close.text = "Continue playing"
  close.custom_minimum_size = Vector2(220,54)
  dialog.confirmed.connect(dialog.queue_free)
  dialog.canceled.connect(dialog.queue_free)
  dialog.popup_centered(Vector2i(580,260))
