extends Node
signal changed
signal rewarded(amount: int)
const STORE := preload("res://scripts/ads/rewarded_store.gd")
const MOCK := preload("res://scripts/ads/mock_ad_adapter.gd")
const CONFIG := preload("res://scripts/core/economy_config.gd")
var store: RefCounted = STORE.new()
var adapter: Node
var clock: RefCounted = preload("res://scripts/ads/ad_clock.gd").new()
var message := "Ads unavailable. Offline campaign remains available."
var context := ""
var foreground := true
var active_token := ""
var phase := "idle"
var presentation_token := ""
var anchor_wall := 0
var anchor_ticks := 0
var request_ticks := 0
var last_reward_ticks := -1
var earned_not_journaled: Dictionary = {}

func _ready() -> void:
 anchor_wall = clock.wall_seconds()
 anchor_ticks = clock.monotonic_msec()
 store.load_history()
 # Persisted pending earnings survive process death; abandoned loads/shows do not.
 if not store.blocked:
  store.data.active = {}
  recover_pending()
 var simulate := MOCK.permitted() and "--rewarded-ads-simulate" in OS.get_cmdline_user_args()
 var provider: Node = MOCK.new() if simulate else preload("res://scripts/ads/poing_admob_adapter.gd").new()
 if simulate:
  message = "EDITOR SIMULATION / Optional ad callbacks; no real advertising."
 install_adapter(provider)

func install_adapter(provider: Node) -> void:
 adapter = provider
 add_child(adapter)
 adapter.ad_loaded.connect(_loaded)
 adapter.earned.connect(_earned)
 adapter.closed.connect(_closed)
 adapter.failed.connect(_failed)
 adapter.status.connect(func(value: String): message = value; changed.emit())

func configure_development(provider: Node, test_clock: RefCounted = null) -> bool:
 if not MOCK.permitted() or phase != "idle":
  return false
 remove_child(adapter)
 adapter.queue_free()
 if test_clock != null:
  clock = test_clock
  anchor_wall = clock.wall_seconds()
  anchor_ticks = clock.monotonic_msec()
 install_adapter(provider)
 message = "EDITOR SIMULATION / No real advertising."
 changed.emit()
 return true

func now() -> int:
 return anchor_wall+int((clock.monotonic_msec()-anchor_ticks)/1000.0)

func clock_safe() -> bool:
 return absi(clock.wall_seconds()-now()) <= int(CONFIG.values.rewarded_ads.clock_tolerance_seconds) and clock.wall_seconds()+int(CONFIG.values.rewarded_ads.clock_tolerance_seconds) >= int(store.data.high_water)

func remaining() -> int:
 var used := int(store.data.used) if int(store.data.day) == int(now()/86400.0) else 0
 return maxi(0,int(CONFIG.values.rewarded_ads.daily_limit)-used)

func cooldown_remaining() -> int:
 var delay := int(CONFIG.values.rewarded_ads.cooldown_seconds)
 var wall_left := maxi(0,int(store.data.last_reward)+delay-now()) if int(store.data.last_reward) > 0 else 0
 var monotonic_left := maxi(0,delay-int((clock.monotonic_msec()-last_reward_ticks)/1000.0)) if last_reward_ticks >= 0 else 0
 return maxi(wall_left,monotonic_left)

func offer() -> Dictionary:
 var reason := ""
 if not SaveManager.has_campaign():
  reason = "Start a campaign first."
 elif store.blocked:
  reason = store.error
 elif phase != "idle":
  reason = "Saving earned reward…" if phase == "pending" else "Loading ad…" if phase == "loading" else "Ad in progress…"
 elif not foreground or context not in ["map","arsenal"]:
  reason = "Optional ads are available only in campaign menus."
 elif not clock_safe():
  reason = "Clock change detected; ad rewards unavailable."
 elif remaining() == 0:
  reason = "Daily reward limit reached (UTC)."
 elif cooldown_remaining() > 0:
  reason = "Next optional ad in %ds." % cooldown_remaining()
 elif store.data.transactions.size() >= STORE.MAX_RECORDS:
  reason = "Ad history full; offline campaign remains available."
 elif not adapter.available():
  reason = "Ads unavailable. Offline campaign remains available."
 return {"enabled":reason.is_empty(),"reason":reason,"amount":int(CONFIG.values.rewarded_ads.reward),"remaining":remaining(),"limit":int(CONFIG.values.rewarded_ads.daily_limit),"message":message,"phase":phase}

func set_context(value: String) -> void:
 context = value
 if context not in ["map","arsenal"] and phase == "loading":
  _failed(active_token,"Ad request canceled after leaving the campaign menu.")
 changed.emit()

func request() -> bool:
 if not offer().enabled:
  message = str(offer().reason)
  changed.emit()
  return false
 if str(SaveManager.state.get("ad_campaign_id","")).is_empty():
  var previous := SaveManager.state.duplicate(true)
  SaveManager.state.ad_campaign_id = Crypto.new().generate_random_bytes(16).hex_encode()
  if not SaveManager.persist():
   SaveManager.state = previous
   message = SaveManager.last_error
   changed.emit()
   return false
 var previous: Dictionary = store.data.duplicate(true)
 active_token = Crypto.new().generate_random_bytes(16).hex_encode()
 store.data.active = {"id":active_token,"campaign_id":SaveManager.state.ad_campaign_id,"amount":int(CONFIG.values.rewarded_ads.reward),"phase":"loading"}
 store.data.high_water = maxi(int(store.data.high_water),now())
 if not store.persist():
  store.data = previous
  active_token = ""
  message = store.error
  changed.emit()
  return false
 phase = "loading"
 request_ticks = clock.monotonic_msec()
 message = "Loading optional ad…"
 changed.emit()
 adapter.prepare(active_token)
 return true

func _loaded(id: String) -> void:
 if id != active_token or phase != "loading":
  return
 if not foreground or context not in ["map","arsenal"]:
  _failed(id,"Ad canceled; return to a campaign menu and request it again.")
  return
 store.data.active.phase = "showing"
 if not store.persist():
  _failed(id,store.error)
  return
 phase = "showing"
 presentation_token = id
 message = "Optional ad in progress…"
 changed.emit()
 adapter.present(id)

func _earned(id: String, provider_transaction_id: String = "") -> void:
 if id != active_token or phase not in ["showing","pending"]:
  return
 if provider_transaction_id.length() > 256:
  _failed(id,"Invalid provider transaction identifier.")
  return
 if not earned_not_journaled.is_empty():
  retry_reward_save()
  return
 if store.data.transactions.has(id):
  recover_pending()
  return
 if not provider_transaction_id.is_empty():
  for record in store.data.transactions.values():
   if record.provider_transaction_id == provider_transaction_id:
    _failed(id,"Duplicate provider reward rejected.")
    return
 var record: Dictionary = store.data.active.duplicate(true)
 if record.is_empty():
  return
 earned_not_journaled = {"id":id,"campaign_id":record.campaign_id,"amount":record.amount,"day":int(now()/86400.0),"status":"pending","provider_transaction_id":provider_transaction_id.left(256)}
 phase = "pending"
 last_reward_ticks = clock.monotonic_msec()
 retry_reward_save()

func retry_reward_save() -> bool:
 if phase != "pending":
  return false
 if not earned_not_journaled.is_empty():
  var record: Dictionary = earned_not_journaled.duplicate(true)
  var previous: Dictionary = store.data.duplicate(true)
  if int(store.data.day) != int(record.day):
   store.data.day = int(record.day)
   store.data.used = 0
  store.data.used += 1
  store.data.last_reward = now()
  store.data.high_water = maxi(int(store.data.high_water),now())
  record.erase("id")
  store.data.transactions[active_token] = record
  store.data.active = {}
  if not store.persist():
   store.data = previous
   message = store.error
   changed.emit()
   return false
  earned_not_journaled = {}
 return recover_pending()

func recover_pending() -> bool:
 if store.blocked:
  return false
 for id in store.data.transactions:
  var record: Dictionary = store.data.transactions[id]
  if record.status != "pending":
   continue
  phase = "pending"
  active_token = id
  if not SaveManager.has_campaign() or str(SaveManager.state.get("ad_campaign_id","")) != str(record.campaign_id):
   record.status = "forfeited"
  else:
   # Credit and receipt are one campaign snapshot. Replay after a crash is inert.
   var receipts: Dictionary = SaveManager.state.get("ad_receipts",{})
   if not receipts.has(id):
    var previous := SaveManager.state.duplicate(true)
    if int(SaveManager.state.credits)+int(record.amount) > 1000000000:
     message = "War Credit balance limit reached; earned reward is pending."
     changed.emit()
     return false
    SaveManager.state.credits += int(record.amount)
    SaveManager.state.ad_receipts[id] = int(record.amount)
    if not SaveManager.persist():
     SaveManager.state = previous
     message = SaveManager.last_error+" Earned reward is pending; retry saving."
     changed.emit()
     return false
    EconomyManager.balance_changed.emit()
    rewarded.emit(int(record.amount))
   record.status = "credited"
  if not store.persist():
   record.status = "pending"
   message = "Reward recorded; finalizing receipt. Retry saving."
   changed.emit()
   return false
  message = "+%d War Credits saved." % int(record.amount) if record.status == "credited" else "Previous campaign reward closed; new campaign unchanged."
 phase = "showing_rewarded" if not presentation_token.is_empty() else "idle"
 active_token = presentation_token
 changed.emit()
 return true

func _closed(id: String) -> void:
 if id != presentation_token:
  return
 presentation_token = ""
 if phase == "pending":
  return
 if phase == "showing_rewarded":
  phase = "idle"
  active_token = ""
  changed.emit()
 else:
  _failed(id,"Ad closed without earned reward. No War Credits granted.")

func _failed(id: String, reason: String) -> void:
 if id != active_token or phase == "pending":
  return
 store.data.active = {}
 if not store.persist():
  reason += " "+store.error
 phase = "idle"
 presentation_token = ""
 active_token = ""
 adapter.discard()
 message = reason
 changed.emit()

func set_foreground(value: bool) -> void:
 foreground = value
 if not value and phase == "loading":
  _failed(active_token,"Ad loading canceled while app is backgrounded.")
 # An ad Activity itself can background Godot. Keep an already-presented session
 # locked and accept its legitimate earned callback, never award on resume alone.
 changed.emit()

func _notification(what: int) -> void:
 if what == NOTIFICATION_APPLICATION_PAUSED:
  set_foreground(false)
 elif what == NOTIFICATION_APPLICATION_RESUMED:
  set_foreground(true)

func _process(_delta: float) -> void:
 if phase == "loading" and clock.monotonic_msec()-request_ticks > int(CONFIG.values.rewarded_ads.load_timeout_seconds)*1000:
  _failed(active_token,"Ad request timed out. Offline gameplay remains available.")
