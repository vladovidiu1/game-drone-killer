extends Node
signal balance_changed
const MAX_LEVEL := 5

func add_credits(amount: int) -> void:
 SaveManager.state.credits = maxi(0, int(SaveManager.state.get("credits", 0)) + amount)
 balance_changed.emit()

func upgrade_cost() -> int:
 return 100 + int(SaveManager.state.get("damage_level", 0)) * 75

func buy_damage() -> bool:
 if not SaveManager.has_campaign() or int(SaveManager.state.damage_level) >= MAX_LEVEL:
  return false
 var cost := upgrade_cost()
 if int(SaveManager.state.credits) < cost:
  return false
 var previous := SaveManager.state.duplicate(true)
 SaveManager.state.credits -= cost
 SaveManager.state.damage_level += 1
 if not SaveManager.persist():
  SaveManager.state = previous
  return false
 balance_changed.emit()
 return true
