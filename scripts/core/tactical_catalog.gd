extends RefCounted
# Shared immutable tuning; each battle owns its separate RNG and plans.
static var DATA: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/tactical_director.json"))
