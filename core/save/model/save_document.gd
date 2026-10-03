class_name NucleusSaveDocument
extends RefCounted
## In-memory save container independent from its on-disk codec.

const MAGIC: String = "NUCLEUS_SAVE"
const CONTAINER_VERSION: int = 1

var slot_id: String
var kind: int = NucleusSaveTypes.Kind.MANUAL
var schema_version: int = 1

var created_at_unix: int = 0
var updated_at_unix: int = 0

var game_version: String = ""
var engine_version: String = ""

var metadata: Dictionary = {}
var payload: Dictionary = {}
var integrity: Dictionary = {}


func to_dictionary(include_integrity: bool = true) -> Dictionary:
	var document: Dictionary = {
		"nucleus": {
			"magic": MAGIC,
			"container_version": CONTAINER_VERSION,
			"slot_id": slot_id,
			"kind": kind,
			"schema_version": schema_version,
			"created_at_unix": created_at_unix,
			"updated_at_unix": updated_at_unix,
			"game_version": game_version,
			"engine_version": engine_version,
		},
		"metadata": metadata.duplicate(true),
		"payload": payload.duplicate(true),
	}

	if include_integrity:
		document["integrity"] = integrity.duplicate(true)

	return document


static func from_dictionary(data: Dictionary) -> NucleusSaveDocument:
	if not data.has("nucleus"):
		return null

	var nucleus_data: Variant = data["nucleus"]

	if typeof(nucleus_data) != TYPE_DICTIONARY:
		return null

	if str(nucleus_data.get("magic", "")) != MAGIC:
		return null

	if int(nucleus_data.get("container_version", 0)) != CONTAINER_VERSION:
		return null

	var document := NucleusSaveDocument.new()
	document.slot_id = str(nucleus_data.get("slot_id", ""))
	document.kind = int(
		nucleus_data.get("kind", NucleusSaveTypes.Kind.MANUAL)
	)
	document.schema_version = int(nucleus_data.get("schema_version", 0))
	document.created_at_unix = int(
		nucleus_data.get("created_at_unix", 0)
	)
	document.updated_at_unix = int(
		nucleus_data.get("updated_at_unix", 0)
	)
	document.game_version = str(nucleus_data.get("game_version", ""))
	document.engine_version = str(nucleus_data.get("engine_version", ""))

	var metadata_value: Variant = data.get("metadata", {})
	var payload_value: Variant = data.get("payload", {})
	var integrity_value: Variant = data.get("integrity", {})

	if typeof(metadata_value) != TYPE_DICTIONARY:
		return null

	if typeof(payload_value) != TYPE_DICTIONARY:
		return null

	if typeof(integrity_value) != TYPE_DICTIONARY:
		return null

	document.metadata = metadata_value.duplicate(true)
	document.payload = payload_value.duplicate(true)
	document.integrity = integrity_value.duplicate(true)

	return document
