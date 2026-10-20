extends Node
var player: AudioStreamPlayer
var combat_player: AudioStreamPlayer
var combat_streams: Dictionary = {}

func _ready() -> void:
 player = AudioStreamPlayer.new()
 add_child(player)
 combat_player = AudioStreamPlayer.new()
 combat_player.max_polyphony = 4
 combat_player.volume_db = -12
 add_child(combat_player)
 apply_settings()

func apply_settings() -> void:
 AudioServer.set_bus_mute(0, bool(SaveManager.settings.muted))
 AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.001, float(SaveManager.settings.volume))))

func cue(victory: bool) -> void:
 # Headless/Dummy output has no audio consumer; avoid retaining queued playback.
 if AudioServer.get_driver_name() == "Dummy":
  return
 var wav := AudioStreamWAV.new()
 wav.format = AudioStreamWAV.FORMAT_16_BITS
 wav.mix_rate = 22050
 var samples := PackedByteArray()
 samples.resize(6615 * 2)
 for i in 6615:
  var t := float(i) / 22050.0
  var frequency := (660.0 if victory else 180.0)
  var sample := int(sin(t * TAU * frequency) * 9000.0 * (1.0 - float(i) / 6615.0))
  samples.encode_s16(i * 2, sample)
 wav.data = samples
 player.stream = wav
 player.play()

func combat_cue(kind: String) -> void:
 if AudioServer.get_driver_name() == "Dummy":
  return
 if not combat_streams.has(kind):
  var duration := 0.045 if kind == "shot" else 0.09
  var frequency := 200.0 if kind == "shot" else (900.0 if kind == "hit" else 440.0)
  var stream := AudioStreamWAV.new()
  stream.format = AudioStreamWAV.FORMAT_16_BITS
  stream.mix_rate = 22050
  var count := int(duration*stream.mix_rate)
  var samples := PackedByteArray()
  samples.resize(count*2)
  for i in count:
   var time := float(i)/stream.mix_rate
   var envelope := 1.0-float(i)/count
   var value := sin(time*TAU*frequency*(1.0+envelope))
   if kind == "shot":
    value = value*0.5+sin(time*TAU*3109.0)*0.3
   samples.encode_s16(i*2,int(value*envelope*12000))
  stream.data = samples
  combat_streams[kind] = stream
 combat_player.stream = combat_streams[kind]
 combat_player.play()
