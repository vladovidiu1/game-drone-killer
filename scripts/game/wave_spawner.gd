extends Node
# Reusable deterministic scheduler. Battle supplies delta and live enemy count.
signal spawn_requested(kind: String, path_index: int)
signal wave_started(number: int)
signal changed
var waves: Array = []
var wave := -1
var build_time := 12.0
var timer := 0.0
var intermission := true
var finished := false
var pending: Array[Dictionary] = []
var cursor := 0
var total_spawned := 0
var path_count := 1

func configure(definitions: Array, delay: float, routes: int) -> void:
 waves = definitions
 build_time = delay
 path_count = maxi(1, routes)
 wave = -1
 timer = build_time
 intermission = true
 finished = waves.is_empty()
 cursor = 0
 total_spawned = 0
 pending.clear()

func start_early() -> bool:
 if not intermission or finished:
  return false
 wave += 1
 if wave >= waves.size():
  finished = true
  intermission = false
  changed.emit()
  return false
 pending.clear()
 for group in waves[wave].groups:
  for count in int(group.count):
   pending.append({"enemy":str(group.enemy),"path":int(group.get("path",-1)),"formation":str(group.get("formation","column"))})
 if str(waves[wave].get("deployment","sequential")) == "escort":
  var ordered: Array[Dictionary] = []
  var groups: Array = waves[wave].groups.duplicate(true)
  groups.reverse()
  var remaining := pending.size()
  while remaining > 0:
   for group in groups:
    if int(group.count) > 0:
     ordered.append({"enemy":str(group.enemy),"path":int(group.get("path",-1)),"formation":str(group.get("formation","column"))})
     group.count = int(group.count)-1
     remaining -= 1
  pending = ordered
 cursor = 0
 timer = 0.0
 intermission = false
 wave_started.emit(wave + 1)
 changed.emit()
 return true

func tick(delta: float, living_enemies: int) -> void:
 if finished:
  return
 timer -= delta
 if intermission:
  if timer <= 0:
   start_early()
  return
 var spawned_this_tick := false
 while cursor < pending.size() and timer <= 0:
  spawned_this_tick = true
  var entry := pending[cursor]
  var kind := str(entry.enemy)
  cursor += 1
  var path_index := int(entry.path) if int(entry.path) >= 0 else total_spawned % path_count
  if str(entry.formation) == "pincer":
   path_index = 0 if total_spawned%2 == 0 else path_count-1
  elif str(entry.formation) == "fan":
   path_index = (total_spawned/3) % path_count
  total_spawned += 1
  timer += float(waves[wave].interval)
  spawn_requested.emit(kind,path_index)
 if cursor >= pending.size() and living_enemies == 0 and not spawned_this_tick:
  if wave + 1 >= waves.size():
   finished = true
  else:
   intermission = true
   timer = build_time
  changed.emit()

func remaining_to_spawn() -> int:
 if finished:
  return 0
 if intermission:
  var total := 0
  for group in waves[wave+1].groups:
   total += int(group.count)
  return total
 return pending.size() - cursor
