extends RefCounted
# One in-flight transaction. Source stays occupied; destination stays reserved.
const RULES := preload("res://scripts/game/placement_rules.gd")
var battle: Node2D
var source := -1
var destination := -1
var active := false
var elapsed := 0.0
var charged := 0
var actor: Node2D
var message := ""
var moves := 0
var refunded := 0
var spent := 0

func configure(owner_battle: Node2D) -> void:
 battle = owner_battle

func duration() -> float:
 return float(RULES.CONFIG.redeploy_seconds)

func quote(turret: Node2D) -> int:
 if not is_instance_valid(turret):
  return 0
 return int(ceil(turret.purchase_value()*int(preload("res://scripts/core/economy_config.gd").values.battle.redeployment.value_percent)/100.0))

func reserved(index: int) -> bool:
 return active and index == destination

func valid_destination(index: int) -> bool:
 return index >= 0 and index < battle.slots.size() and index != source and battle.placed[index] == null and not reserved(index)

func begin(index: int) -> bool:
 if battle.paused or battle.finished or active or index < 0 or index >= battle.placed.size() or not is_instance_valid(battle.placed[index]) or battle.placed[index].is_queued_for_deletion():
  return false
 source = index
 actor = battle.placed[index]
 destination = -1
 message = "Tap a highlighted empty slot. Source stays online until confirmation."
 battle.status_changed.emit()
 return true

func choose(index: int) -> bool:
 if battle.paused or battle.finished or active or source < 0:
  return false
 if not valid_destination(index):
  message = "Destination must be a different, unoccupied slot."
  battle.status_changed.emit()
  return false
 destination = index
 var mount: Dictionary = battle.mission_data.emplacements[index]
 message = "Move S%d → S%d / %d BC / %.0fs offline\n%s %s / facing %.0f°" % [source+1,index+1,quote(actor),duration(),str(mount.sector),str(mount.role),float(mount.bearing_degrees)]
 battle.status_changed.emit()
 return true

func confirm() -> bool:
 if battle.paused or battle.finished or active or source < 0 or not is_instance_valid(actor) or actor.is_queued_for_deletion() or battle.placed[source] != actor or not valid_destination(destination):
  return false
 var cost := quote(actor)
 if battle.credits < cost:
  message = "Insufficient Battle Credits."
  battle.status_changed.emit()
  return false
 battle.credits -= cost
 charged = cost
 spent += cost
 elapsed = 0.0
 active = true
 actor.redeploying = true
 actor.target = null
 actor.muzzle = 0.0
 battle.close_build_mode()
 battle.status_changed.emit()
 return true

func tick(delta: float) -> void:
 if not active:
  return
 if not is_instance_valid(actor) or actor.is_queued_for_deletion() or battle.placed[source] != actor or battle.placed[destination] != null:
  cancel()
  return
 elapsed += delta
 if elapsed < duration():
  return
 # Commit ownership exactly once, before UI notifications can re-enter commands.
 var moving: Node2D = actor
 var target_slot := destination
 battle.placed[source] = null
 battle.placed[target_slot] = moving
 moving.position = battle.slots[target_slot]
 moving.set_emplacement(target_slot)
 moving.redeploying = false
 moving.target = null
 moving.scan_remaining = 0.0
 source = -1
 destination = -1
 active = false
 actor = null
 charged = 0
 moves += 1
 message = "Redeployed to S%d. Target lock reacquiring." % (target_slot+1)
 battle.view.effect(moving.position,"build",46,Color("37b7e5"))
 battle.status_changed.emit()
 battle.selection_changed.emit()

func cancel(notify: bool = true) -> void:
 # Clear transaction before returning escrow: repeated end/cancel callbacks are inert.
 var refund := charged
 charged = 0
 active = false
 source = -1
 destination = -1
 elapsed = 0.0
 if is_instance_valid(actor):
  actor.redeploying = false
  actor.target = null
 actor = null
 for index in battle.placed.size():
  if battle.placed[index] != null and (not is_instance_valid(battle.placed[index]) or battle.placed[index].is_queued_for_deletion()):
   battle.placed[index] = null
 battle.credits += refund
 refunded += refund
 message = "Move canceled / %d BC refunded" % refund if refund > 0 else "Move selection canceled."
 if notify:
  battle.status_changed.emit()
  battle.selection_changed.emit()
