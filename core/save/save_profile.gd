class_name NucleusSaveProfile
extends Resource
## Application-level storage policy for Nucleus saves.
##
## This Resource configures infrastructure only. Credentials are never stored
## here and must be supplied to [NucleusSave] at runtime.

@export_group("Storage")
@export var base_directory: String = "user://saves"
@export_enum("Binary:0", "Text Variant:1", "JSON:2")
var default_format: int = NucleusSaveTypes.Format.BINARY
@export_range(1, 8, 1, "or_greater") var backup_count: int = 2
@export_range(1, 1024, 1, "or_greater") var max_file_size_mb: int = 64

@export_group("Security")
@export_enum("None:0", "Password:1", "Raw 32-byte Key:2")
var encryption_mode: int = NucleusSaveTypes.Encryption.NONE

@export_group("Schema")
@export_range(1, 2147483647, 1, "or_greater")
var schema_version: int = 1
@export var rewrite_migrated_saves: bool = true
@export var migrations: Array[NucleusSaveMigration] = []


func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()

	if base_directory.is_empty():
		errors.append("base_directory cannot be empty")
	elif not base_directory.is_absolute_path():
		errors.append("base_directory must be an absolute res:// or user:// path")

	if schema_version < 1:
		errors.append("schema_version must be at least 1")

	if backup_count < 1:
		errors.append("backup_count must be at least 1")

	if max_file_size_mb < 1:
		errors.append("max_file_size_mb must be at least 1")

	for migration: NucleusSaveMigration in migrations:
		if migration == null:
			errors.append("migrations cannot contain null resources")
			continue

		errors.append_array(migration.get_validation_errors())

	return errors
