extends RefCounted
# Installation-wide write-ahead journal, deliberately separate from campaign reset.
const PATH := "user://rewarded_ads.json"
const MAX_RECORDS := 4096
var data: Dictionary = fresh()
var blocked := false
var error := ""

static func fresh() -> Dictionary:
 return {"version":1,"day":0,"used":0,"high_water":0,"last_reward":0,"active":{},"transactions":{}}

static func number(value: Variant, low: int, high: int) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and value == int(value) and value >= low and value <= high

static func token(value: Variant) -> bool:
 return value is String and value.length() == 32 and value.is_valid_hex_number(false)

static func validate(value: Variant) -> Dictionary:
 if not value is Dictionary or value.get("version") is bool or value.get("version") != 1:
  return {}
 for key in ["day","used","high_water","last_reward"]:
  if not number(value.get(key),0,100000000000):
   return {}
 if not value.get("active") is Dictionary or not value.get("transactions") is Dictionary or value.transactions.size() > MAX_RECORDS:
  return {}
 var result: Dictionary = value.duplicate(true)
 if not result.active.is_empty():
  if not token(result.active.get("id")) or not token(result.active.get("campaign_id")) or not number(result.active.get("amount"),1,1000000) or result.active.get("phase") not in ["loading","showing"]:
   return {}
 for id in result.transactions:
  var record: Variant = result.transactions[id]
  if not token(id) or not record is Dictionary or not token(record.get("campaign_id")) or not number(record.get("amount"),1,1000000) or not number(record.get("day"),0,100000000000) or record.get("status") not in ["pending","credited","forfeited"] or not record.get("provider_transaction_id") is String or record.provider_transaction_id.length() > 256:
   return {}
 return result

static func read(path: String) -> Variant:
 var file := FileAccess.open(path,FileAccess.READ)
 if file == null or file.get_length() > 4*1024*1024:
  return null
 var parser := JSON.new()
 return parser.data if parser.parse(file.get_as_text()) == OK else null

func load_history() -> void:
 data = fresh()
 blocked = false
 error = ""
 if FileAccess.file_exists(PATH):
  var valid := validate(read(PATH))
  if not valid.is_empty():
   data = valid
   return
  blocked = true
 elif FileAccess.file_exists(PATH+".bak"):
  blocked = true
 if blocked:
  # Older backup + newer campaign credit could reopen a consumed daily slot.
  # Fail closed for ads; never reset quota on corrupt/deleted history.
  error = "Ad history needs recovery. Offline gameplay is unaffected."

func persist() -> bool:
 if blocked or validate(data).is_empty():
  error = "Ad history unavailable; reward not saved."
  return false
 var file := FileAccess.open(PATH+".tmp",FileAccess.WRITE)
 if file == null:
  error = "Cannot save ad transaction. Free storage and retry."
  return false
 file.store_string(JSON.stringify(data))
 file.flush()
 var code := file.get_error()
 file.close()
 if code != OK or validate(read(PATH+".tmp")).is_empty():
  error = "Ad transaction verification failed."
  return false
 if FileAccess.file_exists(PATH):
  if DirAccess.copy_absolute(PATH,PATH+".bak.tmp") != OK or DirAccess.rename_absolute(PATH+".bak.tmp",PATH+".bak") != OK:
   error = "Cannot preserve ad history."
   return false
 if DirAccess.rename_absolute(PATH+".tmp",PATH) != OK:
  error = "Cannot replace ad history."
  return false
 error = ""
 return true
