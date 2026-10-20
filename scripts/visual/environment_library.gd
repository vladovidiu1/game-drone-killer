extends RefCounted
# Visual identity is separate from combat conditions; no gameplay writes.
static var DATA: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/environment/library.json"))
