extends Node
# Reusable deterministic scheduler. Battle supplies delta and live enemy count.
signal spawn_requested(kind: String, path_index: int)
signal wave_started(number: int)
signal attack_announced(plan: Dictionary)
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
var hold_initial := false
var director: RefCounted
var plan: Dictionary = {}
var warning_remaining := 0.0

func configure(definitions: Array, delay: float, routes: int, attack_director: RefCounted = null) -> void:
 director = attack_director
 plan = {}
 warning_remaining = 0.0
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
 if director != null and not finished:
  prepare_next()

func prepare_next() -> void:
 plan = director.prepare(wave+1,waves[wave+1])
 warning_remaining = float(plan.warning_seconds)
 timer = maxf(build_time,warning_remaining)
 attack_announced.emit(plan)

func start_early() -> bool:
 if not intermission or finished or warning_remaining > 0:
  return false
 wave += 1
 if wave >= waves.size():
  finished = true
  intermission = false
  changed.emit()
  return false
 pending.clear()
 if director != null:
  pending.assign(plan.entries.duplicate(true))
 else:
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
  warning_remaining = maxf(0.0,warning_remaining-delta)
  if timer <= 0 and not (hold_initial and wave < 0):
   start_early()
  if hold_initial and wave < 0:
   timer = maxf(0,timer)
  return
 var spawned_this_tick := false
 while cursor < pending.size() and timer <= 0:
  spawned_this_tick = true
  var entry := pending[cursor]
  var kind := str(entry.enemy)
  cursor += 1
  var path_index := int(entry.path) if int(entry.path) >= 0 else total_spawned % path_count
  if not entry.get("directed",false) and str(entry.formation) == "pincer":
   path_index = 0 if total_spawned%2 == 0 else path_count-1
  elif not entry.get("directed",false) and str(entry.formation) == "fan":
   path_index = (total_spawned/3) % path_count
  total_spawned += 1
  var burst_size := maxi(1,int(waves[wave].get("burst_size",1)))
  timer += float(waves[wave].get("burst_gap",waves[wave].interval)) if cursor%burst_size != 0 else float(waves[wave].interval)
  spawn_requested.emit(kind,path_index)
 if cursor >= pending.size() and living_enemies == 0 and not spawned_this_tick:
  if director != null:
   director.complete(wave)
  if wave + 1 >= waves.size():
   finished = true
  else:
   intermission = true
   timer = build_time
   if director != null:
    prepare_next()
  changed.emit()

func remaining_to_spawn() -> int:
 if finished:
  return 0
 if intermission:
  if not plan.is_empty():
   return plan.entries.size()
  var total := 0
  for group in waves[wave+1].groups:
   total += int(group.count)
  return total
 return pending.size() - cursor
