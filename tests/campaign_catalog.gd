extends Node
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(message)

func _ready() -> void:
 var bosses := 0
 var layouts: Dictionary = {}
 check(CampaignManager.missions.size() == 25,"Exactly 25 territories")
 for mission in CampaignManager.missions:
  var id := int(mission.id)
  check(id >= 1 and id <= 25 and CampaignManager.mission(id) == mission,"Contiguous unique mission ID")
  check(bool(mission.playable),"Every territory is implemented")
  for field in ["name","location","story","intel","preparation","objective"]:
   check(mission.get(field) is String and not str(mission[field]).is_empty(),"Mission %d missing %s" % [id,field])
  check(int(mission.reward) > 0 and int(mission.starting_credits) >= 100 and int(mission.base_health) == 1000,"Mission economy and base health")
  check(mission.waves.size() >= 5 and mission.paths.size() >= 2 and mission.slots.size() >= 5,"Mission geometry/waves")
  var layout := JSON.stringify([mission.paths,mission.slots])
  check(not layouts.has(layout),"Each territory has a distinct layout")
  layouts[layout] = true
  for slot in mission.slots:
   check(slot.size() == 2 and float(slot[0]) > 65 and float(slot[0]) < 900 and float(slot[1]) >= 200 and float(slot[1]) < 560,"Safe turret slot")
  for path in mission.paths:
   check(path.size() >= 3 and int(path.back()[0]) == 560 and int(path.back()[1]) == 600,"Path terminates at defended base")
   for index in range(1,path.size()):
    check(Vector2(float(path[index][0]),float(path[index][1])).distance_to(Vector2(float(path[index-1][0]),float(path[index-1][1]))) > 0,"Path segment nonzero")
  for wave in mission.waves:
   check(float(wave.interval) > 0 and not wave.groups.is_empty(),"Wave scheduler has valid interval/groups")
   for group in wave.groups:
    check(CampaignManager.enemies.has(str(group.enemy)) and int(group.count) > 0,"All waves reference existing enemy definitions")
    check(int(group.get("path",0)) >= 0 and int(group.get("path",0)) < mission.paths.size(),"Group route exists")
    check(str(group.get("formation","column")) in ["column","fan","pincer"],"Supported formation")
  check(float(mission.speed_multiplier) >= 1 and float(mission.speed_multiplier) <= 1.25,"Speed progression bounded")
  check(mission.environment.kind in ["clear","dust","interference"],"Environmental condition exists")
  if id%5 == 0:
   bosses += 1
   check(mission.has("boss") and CampaignManager.enemies.has(str(mission.boss)),"Chapter boss reference")
   var definition: Dictionary = CampaignManager.enemies[str(mission.boss)]
   check(bool(definition.boss) and definition.ai.phases.size() >= 3,"Multiple boss phases")
   check(mission.waves.back().groups[0].enemy == mission.boss,"Boss appears in final wave")
   check(not str(mission.narrative).is_empty(),"Chapter victory has narrative")
   var previous := 2.0
   for phase in definition.ai.phases:
    check(float(phase.threshold) < previous and float(phase.threshold) > 0,"Ordered phase thresholds")
    previous = float(phase.threshold)
    check(float(phase.windup) >= 1.5 and float(phase.attack_interval) > float(phase.windup),"Boss attacks offer reaction time")
    check(str(phase.attack) in ["spawn","emp","barrage"],"Known boss attack")
    for kind in phase.support:
     check(CampaignManager.enemies.has(str(kind)) and not bool(CampaignManager.enemies[str(kind)].get("boss",false)),"Valid non-boss support")
   check(float(definition.health) <= 3500 and float(definition.ai.weakpoint_radius) >= 12,"Bounded HP and hittable weakpoint")
 check(bosses == 5,"Exactly five boss encounters")
 for key in CampaignManager.enemies:
  var unit: Dictionary = CampaignManager.enemies[key]
  check(float(unit.health) > 0 and float(unit.speed) > 0 and int(unit.reward) > 0 and int(unit.damage) > 0,"Valid enemy combat/economy stats")
 print("CATALOG: %d checks, %d failures" % [checks,failures])
 get_tree().quit(1 if failures else 0)
