"""Inspect pinned upstream API/docs; does not claim Android SDK execution."""
from pathlib import Path
import hashlib,json,re,subprocess,sys
root=Path(__file__).resolve().parents[1]
source=Path(sys.argv[1]) if len(sys.argv)>1 else Path('/tmp/frontline-m4-admob')
commit=subprocess.check_output(['git','-C',str(source),'rev-parse','HEAD'],text=True).strip()
assert commit=='615974e9f66921a54e3c71c33db0856bdbf19d13'
prefix='platforms/godot_editor/addons/admob/gdscript/src/'
contracts={
 'api/MobileAds.gd':['initialize','set_request_configuration'],
 'api/RewardedAd.gd':['show','destroy','set_server_side_verification_options','full_screen_content_callback'],
 'api/RewardedAdLoader.gd':['load'],
 'api/core/AdRequest.gd':[],
 'api/core/RequestConfiguration.gd':['tag_for_child_directed_treatment','tag_for_under_age_of_consent','max_ad_content_rating'],
 'api/core/ServerSideVerificationOptions.gd':['custom_data'],
 'api/listeners/RewardedAdLoadCallback.gd':['on_ad_loaded','on_ad_failed_to_load'],
 'api/listeners/FullScreenContentCallback.gd':['on_ad_dismissed_full_screen_content','on_ad_failed_to_show_full_screen_content'],
 'api/listeners/OnUserEarnedRewardListener.gd':['on_user_earned_reward'],
 'api/listeners/OnInitializationCompleteListener.gd':['on_initialization_complete'],
 'ump/api/UserMessagingPlatform.gd':['consent_information','load_consent_form','show_privacy_options_form'],
 'ump/api/ConsentInformation.gd':['update','get_consent_status','get_is_consent_form_available','get_privacy_options_requirement_status'],
 'ump/api/ConsentForm.gd':['show'],
 'ump/core/ConsentRequestParameters.gd':['tag_for_under_age_of_consent'],
}
files=[]
for path,symbols in contracts.items():
 file=source/prefix/path;body=file.read_text()
 for name in symbols: assert re.search(r'\b'+name+r'\b',body),(path,name)
 files.append({'path':prefix+path,'symbols':symbols,'sha256':hashlib.sha256(file.read_bytes()).hexdigest(),'url':f'https://github.com/poing-studios/godot-admob-plugin/blob/{commit}/{prefix}{path}'})
for path in ['README.md','docs/ad_formats/rewarded.md','docs/privacy/user_messaging_tools/get_started.md','platforms/android/README.md','platforms/android/build.gradle','platforms/android/src/ads/config/poing_godot_admob_ads.gd','platforms/godot_editor/addons/admob/internal/services/project_settings_service.gd']:
 file=source/path;files.append({'path':path,'sha256':hashlib.sha256(file.read_bytes()).hexdigest(),'url':f'https://github.com/poing-studios/godot-admob-plugin/blob/{commit}/{path}'})
bridge=(root/'scripts/ads/poing_admob_adapter.gd').read_text()
for path in re.findall(r'api\("([^"]+)"\)',bridge):assert path in contracts,path
assert 'can_request_ads' not in (source/prefix/'ump/api/ConsentInformation.gd').read_text()
assert 'ConsentStatus { UNKNOWN, NOT_REQUIRED, REQUIRED, OBTAINED }' in (source/prefix/'ump/api/ConsentInformation.gd').read_text()
report={'plugin':'Poing Studios Godot AdMob','version':'5.1.0','commit':commit,'license':'MIT (Google SDK has separate Google terms)','godot_claimed_support':'4.5.0+','observed_android_compile_sdk':35,'observed_android_min_sdk':24,'observed_ad_dependency':'com.google.android.libraries.ads.mobile.sdk:ads-mobile-sdk:1.4.0','android_aar_for_4_6_3_verified':False,'native_sdk_execution_verified':False,'files':files}
(root/'docs/m4/plugin_sources.json').write_text(json.dumps(report,indent=2)+'\n')
print(f'Pinned Poing 5.1.0 source contract: {len(contracts)} API files, {len(files)} total sources; Android execution NOT verified')
