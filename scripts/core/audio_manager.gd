extends Node
# Keep distinct voices: replacing one player's stream on every hit used to cut
# off shots/reloads. Explicit stream playback also supports runtime PCM on Android.
var player: AudioStreamPlayer
var combat_players: Dictionary = {}
var combat_streams: Dictionary = {}
var last_cue: Dictionary = {}
const MENU_MUSIC := preload("res://assets/audio/night_watch.ogg")
var music_player: AudioStreamPlayer
var music_context := "menu"
var battle_paused := false
var foreground := true
var ad_playing := false

func _ready() -> void:
 player = _voice(-2.0)
 music_player = _voice(-18.0)
 music_player.max_polyphony = 1
 music_player.stream = MENU_MUSIC
 apply_settings()

func _voice(level: float) -> AudioStreamPlayer:
 var voice := AudioStreamPlayer.new()
 voice.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
 voice.max_polyphony = 4
 voice.volume_db = level
 add_child(voice)
 return voice

func apply_settings() -> void:
 AudioServer.set_bus_mute(0, bool(SaveManager.settings.muted))
 AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.001, float(SaveManager.settings.volume))))
 _sync_music()

func cue(victory: bool) -> void:
 if AudioServer.get_driver_name() == "Dummy":
  return
 player.stream = sound("victory" if victory else "defeat")
 player.play()

func sound(kind: String) -> AudioStreamWAV:
 if combat_streams.has(kind):
  return combat_streams[kind]
 var duration := 0.30 if kind in ["victory","defeat","explosion"] else 0.20 if kind in ["radar","build"] else 0.075
 var frequency := float({"victory":660,"defeat":180,"radar":640,"build":520,"shot":160,"impact":280,"explosion":70,"reload":360,"ready":880,"hit":900,"click":720}.get(kind,440))
 var stream := AudioStreamWAV.new()
 stream.format = AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate = 44100
 var count := int(duration*stream.mix_rate)
 var samples := PackedByteArray()
 samples.resize(count*2)
 for i in count:
  var time := float(i)/stream.mix_rate
  var progress := float(i)/count
  var envelope := minf(1.0,time/0.003)*pow(1.0-progress,1.5)
  var value := sin(time*TAU*frequency*(1.0+0.4*(1.0-progress)))
  if kind in ["shot","impact","explosion"]:
   value = value*0.65+sin(time*TAU*3109.0)*sin(time*TAU*1783.0)*0.35
  samples.encode_s16(i*2,int(value*envelope*24000))
 stream.data = samples
 combat_streams[kind] = stream
 return stream

func combat_cue(kind: String) -> void:
 if AudioServer.get_driver_name() == "Dummy":
  return
 # Bound aggregate combat volume without cutting off another cue's voice.
 var now := Time.get_ticks_msec()
 if now-int(last_cue.get(kind,-1000)) < (75 if kind != "click" else 30):
  return
 last_cue[kind] = now
 if not combat_players.has(kind):
  var new_voice := _voice(-5.0 if kind in ["shot","impact","explosion"] else -2.0)
  new_voice.stream = sound(kind)
  combat_players[kind] = new_voice
 var voice: AudioStreamPlayer = combat_players[kind]
 voice.play()

func set_context(value: String) -> void:
 music_context = value
 battle_paused = false
 _sync_music()

func set_battle_paused(value: bool) -> void:
 if music_context == "game":
  battle_paused = value
  _sync_music()

func set_ad_playing(value: bool) -> void:
 ad_playing = value
 _sync_music()

func music_allowed() -> bool:
 return foreground and not ad_playing and bool(SaveManager.settings.get("music_enabled",true)) and not bool(SaveManager.settings.muted) and float(SaveManager.settings.volume) > 0 and (music_context != "game" or battle_paused)

func _sync_music() -> void:
 if not is_instance_valid(music_player):
  return
 if not music_allowed():
  music_player.stream_paused = true
  return
 # Dummy has no real audio consumer. Preserve semantic state without queuing audio.
 if AudioServer.get_driver_name() == "Dummy":
  return
 if not music_player.playing:
  music_player.play()
 music_player.stream_paused = false

func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:
  foreground = false
  _sync_music()
 elif what in [NOTIFICATION_APPLICATION_FOCUS_IN,NOTIFICATION_APPLICATION_RESUMED]:
  foreground = true
  _sync_music()
