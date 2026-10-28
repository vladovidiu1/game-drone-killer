extends Node
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(message)
func _ready() -> void:
 run.call_deferred()
func settle() -> void:
 for frame in 3:
  await get_tree().process_frame
func run() -> void:
 if "--verify-menu-audio" in OS.get_cmdline_user_args():
  check(not SaveManager.settings.music_enabled,"Separate process restores disabled music preference")
  check(not SaveManager.settings.muted and is_equal_approx(float(SaveManager.settings.volume),0.6),"Music preference leaves effects/master settings intact")
  SaveManager.settings.music_enabled = true
  check(SaveManager.save_settings(),"Restore ordinary music default for later suites")
  finish()
  return
 var before: Dictionary = SaveManager.settings.duplicate(true)
 SaveManager.settings = SaveManager.DEFAULT_SETTINGS.duplicate(true)
 check(SaveManager.validate_settings({"volume":0.6,"muted":false}).music_enabled,"Old settings gain music without erasing volume/mute")
 check(SaveManager.validate_settings({"music_enabled":"false","muted":false}).music_enabled,"Invalid music preference type does not coerce to false")
 var music: AudioStreamOggVorbis = AudioManager.MENU_MUSIC
 check(music.loop and music.get_length() > 47 and music.get_length() < 49,"Real local 48-second Ogg loops")
 check(AudioManager.music_player.volume_db <= -18 and AudioManager.music_player.max_polyphony == 1,"Music stays quiet and cannot stack players")
 AudioManager.set_context("menu")
 check(AudioManager.music_allowed(),"Menu music is enabled by default")
 AudioManager.set_context("game")
 check(not AudioManager.music_allowed(),"Active combat has no background music")
 var battle := preload("res://scenes/gameplay.tscn").instantiate()
 add_child(battle)
 battle.set_physics_process(false)
 battle.set_paused(true)
 check(AudioManager.music_allowed(),"Actual battle pause enables menu music")
 battle.set_paused(false)
 check(not AudioManager.music_allowed(),"Actual battle resume pauses music")
 AudioManager.set_context("arsenal")
 AudioManager.set_ad_playing(true)
 check(not AudioManager.music_allowed(),"Full-screen ad suspends background music")
 AudioManager.set_ad_playing(false)
 check(AudioManager.music_allowed(),"After ad dismissal menu music becomes eligible")
 AudioManager._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
 check(not AudioManager.music_allowed(),"Background/focus loss suspends music")
 AudioManager._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
 check(AudioManager.music_allowed(),"Foreground menu resumes eligibility")
 SaveManager.settings.muted = true
 AudioManager.apply_settings()
 check(not AudioManager.music_allowed() and AudioServer.is_bus_mute(0),"Mute silences music and effects")
 SaveManager.settings.muted = false
 SaveManager.settings.music_enabled = false
 AudioManager.apply_settings()
 check(not AudioManager.music_allowed() and not AudioServer.is_bus_mute(0),"Music switch preserves unmuted combat sounds")
 check(SaveManager.save_settings(),"Music switch persists independently of campaign")
 SaveManager.new_campaign()
 check(not SaveManager.settings.music_enabled,"Campaign reset preserves music preference")
 RewardedAdsManager.set_context("map")
 var balance: int = SaveManager.state.credits
 check(not RewardedAdsManager.offer().enabled and RewardedAdsManager.offer().setup_required,"Missing account remains unavailable instead of inventing ad access")
 var offer := preload("res://scripts/ui/rewarded_ad_offer.gd").new()
 add_child(offer)
 await settle()
 check(not offer.watch.disabled and offer.watch.text == "Ad information","Unconfigured offer is accessible as information")
 offer.watch.pressed.emit()
 await settle()
 var info := offer.get_node_or_null("AdsInformation")
 check(info is AcceptDialog and info.visible,"Ad information really opens")
 check(SaveManager.state.credits == balance and RewardedAdsManager.phase == "idle","Opening ad information never grants credits or requests an ad")
 if info != null:
  info.confirmed.emit()
 offer.queue_free()
 var provider := preload("res://scripts/ads/poing_admob_adapter.gd").new()
 add_child(provider)
 check(not provider.configuration_issue().is_empty(),"Default ad configuration fails closed")
 provider.config = {"enabled":true,"mode":"test","audience":"reviewed_adult_only","compliance_reviewed":true,"privacy_messaging_configured":true,"privacy_policy_url":"https://example.com/privacy","android_app_id":"ca-app-pub-3940256099942544~3347511713"}
 check(not provider.configuration_issue().is_empty(),"Google sample app cannot pretend to own a publisher consent message")
 check(provider.rewarded_unit() == provider.TEST_UNIT,"Test mode uses official Google rewarded test unit")
 provider.queue_free()
 battle.queue_free()
 AudioManager.set_context("menu")
 await settle()
 finish()
func finish() -> void:
 print("MENU AUDIO / ADS: %d checks, %d failures" % [checks,failures])
 get_tree().quit(1 if failures else 0)
