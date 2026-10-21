extends RefCounted
func wall_seconds() -> int:
 return int(Time.get_unix_time_from_system())
func monotonic_msec() -> int:
 return Time.get_ticks_msec()
