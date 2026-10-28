extends Node
# Provider boundary: only earned is a financial event. No provider writes saves.
signal ad_loaded(token: String)
signal earned(token: String, provider_transaction_id: String)
signal closed(token: String)
signal failed(token: String, reason: String)
signal status(text: String)

func available() -> bool:
 return false

func unavailable_reason() -> String:
 return "Ads unavailable. Offline campaign remains available."

func prepare(token: String) -> void:
 failed.emit(token,"Ads unavailable. Offline campaign remains available.")

func present(token: String) -> void:
 failed.emit(token,"Ad presentation unavailable.")

func discard() -> void:
 pass

func privacy_available() -> bool:
 return false

func show_privacy_options() -> void:
 pass
