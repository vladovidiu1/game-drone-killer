extends RefCounted
# Pure stat composition. Catalog/profile snapshots never own input or damage.
static func ammunition(id: String, levels: Dictionary) -> Dictionary:
 var profile: Dictionary = SaveManager.catalog.ammunition[id].duplicate(true)
 var tier := clampi(int(levels.get("ammo_"+id,0)),0,3)
 for key in SaveManager.catalog.projectile_technologies[id].tier_steps:
  profile[key] = float(profile.get(key,0))+float(SaveManager.catalog.projectile_technologies[id].tier_steps[key])*tier
 profile.tier = tier
 return profile

static func turret(kind: String, levels: Dictionary, choices: Dictionary) -> Dictionary:
 var profile: Dictionary = CampaignManager.turrets[kind].duplicate(true)
 profile.merge({"armor_multiplier":1.0,"armor_bypass":0.0,"shield_bypass":0.0,"disable_duration":0.0},false)
 var choice := str(choices.get(kind,""))
 var branches: Dictionary = SaveManager.catalog.turret_specializations[kind]
 if branches.has(choice):
  var data: Dictionary = branches[choice]
  var tier := clampi(int(levels.get(str(data.research),0)),0,3)
  for key in data.factors:
   profile[key] = float(profile[key])*(1.0+float(data.factors[key])*tier)
  for key in data.add:
   profile[key] = float(profile.get(key,0))+float(data.add[key])*tier
  profile.specialization = choice
 return profile
