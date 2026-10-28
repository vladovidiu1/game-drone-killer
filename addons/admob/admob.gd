@tool
extends EditorPlugin
# Project-owned offline exporter for pinned Poing runtime/binaries. No downloads,
# editor mock registration, iOS installation or project-settings mutation.
class AndroidAdsExport extends EditorExportPlugin:
 const LIBRARY := preload("res://addons/admob/android/bin/ads/poing_godot_admob_ads.gd")
 func _get_name() -> String:
  return "FrontlinePoingAdMobAndroid"
 func _supports_platform(platform: EditorExportPlatform) -> bool:
  return platform is EditorExportPlatformAndroid
 func _get_android_libraries(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
  return LIBRARY.new()._get_android_libraries(platform,debug)
 func _get_android_dependencies(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
  return LIBRARY.new()._get_android_dependencies(platform,debug)
 func _get_android_manifest_application_element_contents(_platform: EditorExportPlatform, _debug: bool) -> String:
  return '<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="%s"/>' % str(ProjectSettings.get_setting("admob/general/android/app_id","ca-app-pub-3940256099942544~3347511713"))
 func _export_begin(features: PackedStringArray, _debug: bool, _path: String, _flags: int) -> void:
  if not features.has("android"):
   return
  if not get_option("gradle_build/use_gradle_build"):
   push_error("AdMob needs Gradle export; run python3 tools/setup_android.py first.")
   return
  var config := FileAccess.get_file_as_bytes("res://addons/admob/plugin.cfg")
  add_file("res://addons/admob/plugin.cfg",config,false)
  for notice in ["res://addons/admob/LICENSE","res://assets/ASSET_LICENSE.md","res://assets/ui/fonts/Barlow-OFL.txt","res://assets/ui/fonts/BarlowCondensed-OFL.txt","res://assets/ui/fonts/DejaVu-LICENSE.txt"]:
   add_file(notice,FileAccess.get_file_as_bytes(notice),false)
  # Match the pinned upstream Next-Gen SDK dependency configuration, in the
  # generated/ignored template only. Preserve TLS/checksum verification.
  var path := "res://android/build/build.gradle"
  var text := FileAccess.get_file_as_string(path)
  if not text.contains('exclude group: "com.google.android.gms", module: "play-services-ads"'):
   var output := FileAccess.open(path,FileAccess.WRITE)
   if output == null:
    push_error("AdMob could not configure the generated Android Gradle template.")
    return
   output.store_string(text+'\nconfigurations.configureEach {\n exclude group: "com.google.android.gms", module: "play-services-ads"\n exclude group: "com.google.android.gms", module: "play-services-ads-lite"\n resolutionStrategy.force "androidx.browser:browser:1.8.0"\n}\n')
var exporter: EditorExportPlugin
func _enter_tree() -> void:
 exporter = AndroidAdsExport.new()
 add_export_plugin(exporter)
func _exit_tree() -> void:
 if exporter != null:
  remove_export_plugin(exporter)
