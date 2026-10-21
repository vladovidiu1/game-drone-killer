extends RefCounted
# Shared geometry for targeting, overlays and reconnaissance. No damage/persistence.
static var CONFIG: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/placement.json"))

static func contains(origin: Vector2, point: Vector2, radius: float, bearing: float, degrees: float) -> bool:
 if origin.distance_squared_to(point) > radius*radius+.001:
  return false
 return degrees >= 360 or origin.is_equal_approx(point) or absf(angle_difference(bearing,(point-origin).angle())) <= deg_to_rad(degrees*.5)+.00001

static func description(data: Dictionary) -> String:
 return "ARC %.0f° • TRACK %.0f°/s • LOCK %.2fs" % [float(data.traverse_degrees),float(data.turn_degrees),float(data.acquisition_delay)]
