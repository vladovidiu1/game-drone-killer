extends "res://scripts/ads/ad_adapter.gd"
# Every entry point is editor+debug gated, not merely a configurable boolean.
var scenario := "manual"
var dialog: ConfirmationDialog
var token := ""
var show_count := 0

static func permitted() -> bool:
 return OS.has_feature("editor") and OS.is_debug_build() and not OS.has_feature("android")

func available() -> bool:
 return permitted() and scenario != "unavailable"

func prepare(id: String) -> void:
 if not permitted():
  failed.emit(id,"Simulation is unavailable in exported builds.")
  return
 token = id
 status.emit("EDITOR SIMULATION / Loading — no real advertising")
 if scenario in ["load_failure","consent_denied","unavailable"]:
  failed.emit(id,{"load_failure":"Ad load failed.","consent_denied":"Consent unavailable; no ad requested.","unavailable":"Ad unavailable."}[scenario])
 elif scenario != "delayed":
  ad_loaded.emit.call_deferred(id)

func present(id: String) -> void:
 if not permitted() or id != token:
  return
 show_count += 1
 if scenario == "show_failure":
  failed.emit(id,"Ad presentation failed.")
  return
 status.emit("EDITOR SIMULATION / Ad showing — no real advertising")
 if scenario == "success":
  complete.call_deferred(true)
 elif scenario == "cancel":
  complete.call_deferred(false)
 elif scenario == "manual":
  dialog = ConfirmationDialog.new()
  dialog.title = "EDITOR SIMULATION — NOT A REAL AD"
  dialog.dialog_text = "Development callback test.\nComplete simulates an earned-reward callback.\nClose simulates dismissal without a reward."
  preload("res://scripts/ui/ui_kit.gd").prepare_confirmation(dialog)
  dialog.get_ok_button().text = "Complete simulation"
  dialog.get_cancel_button().text = "Close without reward"
  dialog.confirmed.connect(complete.bind(true))
  dialog.canceled.connect(complete.bind(false))
  get_tree().root.add_child(dialog)
  dialog.popup_centered(Vector2i(580,260))

func complete(reward: bool, transaction_id: String = "") -> void:
 if not permitted() or token.is_empty():
  return
 var id := token
 if reward:
  earned.emit(id,transaction_id)
 closed.emit(id)
 if token == id:
  discard()

func discard() -> void:
 token = ""
 if is_instance_valid(dialog):
  dialog.queue_free()
  dialog = null
