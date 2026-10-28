extends Node
const MOCK := preload("res://scripts/ads/mock_ad_adapter.gd")
const STORE := preload("res://scripts/ads/rewarded_store.gd")
const CONFIG := preload("res://scripts/core/economy_config.gd")
class ConsentMock extends "res://scripts/ads/mock_ad_adapter.gd":
 var consent_open := false
 func consent_ui_active() -> bool:
  return consent_open
class TestClock extends RefCounted:
 var wall := int(Time.get_unix_time_from_system())
 var ticks := 100000
 func wall_seconds() -> int:
  return wall
 func monotonic_msec() -> int:
  return ticks
 func advance(seconds: int) -> void:
  wall += seconds
  ticks += seconds*1000

var checks := 0
var failures := 0
var ads: Node
var provider: Node
var clock: RefCounted
var rows: Array = []

func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error("FAIL: "+message)

func _ready() -> void:
 run.call_deferred()

func frames() -> void:
 await get_tree().process_frame
 await get_tree().process_frame

func fresh(replacement: Node = null) -> void:
 ads.adapter.discard()
 ads.phase = "idle"
 ads.active_token = ""
 ads.presentation_token = ""
 ads.earned_not_journaled = {}
 ads.last_reward_ticks = -1
 ads.store.blocked = false
 ads.store.data = STORE.fresh()
 ads.store.error = ""
 for suffix in ["",".bak",".tmp",".bak.tmp"]:
  var path: String = STORE.PATH+suffix
  if FileAccess.file_exists(path):
   DirAccess.remove_absolute(path)
 SaveManager.new_campaign()
 clock = TestClock.new()
 provider = MOCK.new() if replacement == null else replacement
 provider.scenario = "hold"
 check(ads.configure_development(provider,clock),"editor-only adapter injection allowed in editor test binary")
 ads.set_context("arsenal")
 ads.set_foreground(true)

func start() -> String:
 check(ads.request(),"explicit request accepted")
 var id: String = ads.active_token
 check(not id.is_empty() and ads.phase == "loading","one persisted session owns loading")
 await frames()
 check(ads.phase == "showing" and provider.show_count > 0,"load completion precedes presentation")
 return id

func run() -> void:
 ads = RewardedAdsManager
 if "--verify-ads" in OS.get_cmdline_user_args():
  check(SaveManager.state.credits == 50,"restart recovers pending earned event exactly once")
  check(SaveManager.state.ad_receipts.size() == 1,"restart saves idempotency receipt with credit")
  check(ads.store.data.used == 1 and ads.store.data.transactions.size() == 1,"restart retains installation quota and transaction")
  var id: String = ads.store.data.transactions.keys()[0]
  check(ads.store.data.transactions[id].status == "credited","restart completes pending journal")
  ads._earned(id,"duplicate")
  ads.recover_pending()
  SaveManager.reload_from_disk()
  check(SaveManager.state.credits == 50,"duplicate callback after restart cannot credit again")
  check(not ads.adapter.available() and not ads.request(),"offline/default installation never tries real advertising")
  finish()
  return
 check(OS.has_feature("editor") and OS.is_debug_build(),"simulation tests run in debug editor executable")
 check(not ads.adapter.available(),"native SDK absent: provider fails closed")
 var shipping: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/advertising.json"))
 check(shipping.mode == "test" and shipping.enabled and shipping.compliance_reviewed and shipping.privacy_messaging_configured and shipping.audience == "reviewed_adult_only","Publisher-confirmed build is eligible only for reviewed TEST advertising")
 check(shipping.android_rewarded_test_id == "ca-app-pub-3940256099942544/5224354917" and shipping.android_app_test_id == "ca-app-pub-3940256099942544~3347511713","only official Google Android test identifiers")
 var old_cooldown: int = CONFIG.values.rewarded_ads.cooldown_seconds
 CONFIG.values.rewarded_ads.cooldown_seconds = 0
 fresh()
 var id := await start()
 check(not ads.request(),"concurrent second rewarded session rejected")
 provider.earned.emit(id,"google-test-transaction-1")
 check(SaveManager.state.credits == 50 and ads.phase == "showing_rewarded","earned event credits exactly 50, locks presentation until dismissal")
 check(not ads.request(),"zero cooldown cannot allow concurrent presentations after earned event")
 provider.earned.emit(id,"google-test-transaction-1")
 provider.closed.emit(id)
 provider.discard()
 check(SaveManager.state.credits == 50 and ads.remaining() == 4,"duplicate earned callback consumes one quota and one credit")
 SaveManager.reload_from_disk()
 check(SaveManager.state.credits == 50 and SaveManager.state.ad_receipts.has(id),"credit and receipt persist together")
 ads._earned(id,"google-test-transaction-1")
 check(SaveManager.state.credits == 50,"stale callback ignored after closure")
 rows.append({"scenario":"success + duplicate + save/reload","credits":50,"daily_used":1})
 id = await start()
 provider.complete(false)
 check(SaveManager.state.credits == 50 and ads.remaining() == 4,"canceled/dismissed without reward pays nothing")
 for scenario in ["unavailable","load_failure","show_failure","consent_denied"]:
  provider.scenario = scenario
  ads.request()
  await frames()
  check(SaveManager.state.credits == 50 and ads.remaining() == 4 and ads.phase == "idle","no credit/quota on "+scenario)
 provider.scenario = "hold"
 for i in 4:
  await start()
  provider.complete(true)
 check(SaveManager.state.credits == 250 and ads.remaining() == 0,"five successful events cap daily income at 250 WC")
 check(not ads.request() and "Daily" in ads.offer().reason,"sixth reward blocked")
 rows.append({"scenario":"daily limit","credits":250,"daily_used":5})
 var delta := (int(clock.wall/86400.0)+1)*86400+10-int(clock.wall)
 clock.advance(delta)
 check(ads.remaining() == 5 and ads.offer().enabled,"UTC day reset follows elapsed monotonic time")
 clock.wall -= 600
 check(not ads.request() and "Clock" in ads.offer().reason,"backward wall-clock jump blocks new ads")
 clock.wall += 600+86400
 check(not ads.request(),"forward wall-clock jump without elapsed monotonic time blocks new ads")
 clock.wall -= 86400
 await start()
 provider.complete(true)
 check(ads.store.data.used == 1 and SaveManager.state.credits == 300,"new UTC day consumes exactly one fresh slot")
 SaveManager.new_campaign()
 check(SaveManager.state.credits == 0 and ads.remaining() == 4,"new campaign cannot reset installation-wide daily quota")
 id = await start()
 SaveManager.new_campaign()
 provider.complete(true)
 check(SaveManager.state.credits == 0 and ads.store.data.transactions[id].status == "forfeited","old campaign's earned event never funds a replacement campaign")
 # Backgrounding while loading must not suddenly present on resume.
 provider.scenario = "delayed"
 check(ads.request(),"delayed loading request")
 id = ads.active_token
 var shown: int = provider.show_count
 ads.set_foreground(false)
 provider.ad_loaded.emit(id)
 ads.set_foreground(true)
 check(provider.show_count == shown and SaveManager.state.credits == 0 and ads.phase == "idle","backgrounded loading cancels; resume does not show or award")
 # Native ad Activities themselves can suspend Godot; do not discard a valid show.
 provider.scenario = "hold"
 await start()
 ads.set_foreground(false)
 check(not ads.request(),"background presentation keeps session locked")
 provider.complete(true)
 ads.set_foreground(true)
 check(SaveManager.state.credits == 50,"legitimate earned callback remains valid while native ad backgrounds app")
 fresh(ConsentMock.new())
 provider.scenario = "delayed"
 check(ads.request(),"Explicit ad request can own official consent UI")
 provider.consent_open = true
 id = ads.active_token
 ads.set_foreground(false)
 clock.advance(46)
 ads._process(0)
 check(ads.phase == "loading" and ads.active_token == id,"Official consent UI pausing Godot does not cancel or hit the short ad-load timeout")
 provider.ad_loaded.emit(id)
 check(ads.phase == "ready" and provider.show_count == 0,"Ad finishing after consent waits for Activity resume")
 provider.consent_open = false
 ads.set_foreground(true)
 check(ads.phase == "showing" and provider.show_count == 1,"Consent return presents exactly once while foregrounded")
 provider.complete(true)
 check(SaveManager.state.credits == 50 and ads.remaining() == 4,"Consent lifecycle retains earned-only reward and daily quota")
 fresh()
 provider.scenario = "delayed"
 ads.request()
 id = ads.active_token
 ads.set_context("game")
 provider.ad_loaded.emit(id)
 check(ads.phase == "idle" and provider.show_count == 0 and not ads.request(),"leaving menus invalidates loading; no ads during gameplay")
 ads.set_context("arsenal")
 ads.request()
 clock.advance(46)
 ads._process(0)
 check(ads.phase == "idle" and SaveManager.state.credits == 0,"load timeout does not award or lock normal play")
 fresh()
 CONFIG.values.rewarded_ads.cooldown_seconds = 60
 await start()
 provider.complete(true)
 check(ads.cooldown_remaining() == 60 and not ads.request(),"success starts configurable real-time cooldown")
 clock.advance(60)
 check(ads.offer().enabled,"elapsed monotonic cooldown permits next request")
 CONFIG.values.rewarded_ads.cooldown_seconds = 0
 # Duplicate upstream transaction IDs, when an adapter can provide them.
 id = await start()
 provider.complete(true,"shared-provider-id")
 var balance: int = SaveManager.state.credits
 await start()
 provider.complete(true,"shared-provider-id")
 check(SaveManager.state.credits == balance,"reused provider transaction cannot fund a new local session")
 await start()
 provider.complete(true,"x".repeat(257))
 check(SaveManager.state.credits == balance,"oversized transaction IDs cannot bypass deduplication by truncation")
 # Both storage failure boundaries, no partial financial transaction.
 fresh()
 await start()
 DirAccess.make_dir_absolute(STORE.PATH+".tmp")
 provider.complete(true)
 check(SaveManager.state.credits == 0 and ads.phase == "pending","journal failure cannot grant unrecorded credit")
 DirAccess.remove_absolute(STORE.PATH+".tmp")
 check(ads.retry_reward_save() and SaveManager.state.credits == 50 and ads.remaining() == 4,"retry journals and credits a valid earned event once")
 fresh()
 await start()
 DirAccess.make_dir_absolute(SaveManager.PATH+".tmp")
 provider.complete(true)
 check(SaveManager.state.credits == 0 and ads.phase == "pending" and ads.store.data.used == 1,"campaign write failure retains one durable pending reward without credit")
 DirAccess.remove_absolute(SaveManager.PATH+".tmp")
 check(ads.retry_reward_save() and SaveManager.state.credits == 50,"campaign write recovery saves credit and receipt")
 id = str(ads.store.data.transactions.keys()[0])
 ads.store.data.transactions[id].status = "pending"
 ads.store.persist()
 ads.store.load_history()
 ads.recover_pending()
 check(SaveManager.state.credits == 50 and ads.store.data.transactions[id].status == "credited","crash after campaign credit but before journal completion cannot duplicate reward")
 var file := FileAccess.open(STORE.PATH,FileAccess.WRITE)
 file.store_string("{invalid")
 file.close()
 ads.store.load_history()
 check(ads.store.blocked and not ads.request() and SaveManager.state.credits == 50,"corrupt ad history fails closed without harming campaign bank")
 for version in [1,2,3]:
  var migrated := SaveManager.validate_campaign({"version":version,"frontline":3,"highest":3,"credits":1234,"damage_level":3,"records":{"1":{"victories":1}},"research":{"magazine":2},"unlocks":["armor_piercing"]})
  check(migrated.credits == 1234 and migrated.damage_level == 3 and migrated.research.magazine == 2 and migrated.unlocks.has("armor_piercing") and migrated.ad_receipts.is_empty() and migrated.ad_campaign_id.is_empty(),"v%d migration preserves money/upgrades and grants no ad credits" % version)
 rows.append({"scenario":"storage failures, retry and recovery","duplicate_credits":0,"campaign_compatible_versions":[1,2,3]})
 # Leave a genuine earned callback journaled but not yet credited for fresh process.
 fresh()
 await start()
 DirAccess.make_dir_absolute(SaveManager.PATH+".tmp")
 provider.complete(true)
 DirAccess.remove_absolute(SaveManager.PATH+".tmp")
 check(ads.phase == "pending" and SaveManager.state.credits == 0,"fresh-process fixture has earned reward, zero credited, durable pending journal")
 CONFIG.values.rewarded_ads.cooldown_seconds = old_cooldown
 var report := FileAccess.open("user://rewarded_ad_scenarios.json",FileAccess.WRITE)
 report.store_string(JSON.stringify({"checks":checks,"failures":failures,"real_ads_tested":false,"scenarios":rows},"  "))
 await frames()
 finish()

func finish() -> void:
 print("REWARDED ADS: %d checks, %d failures" % [checks,failures])
 get_tree().quit(1 if failures else 0)
