class_name NucleusTargetAreaSensor2D
extends Area2D
## Native Area2D overlap sensor that feeds one NucleusTargetingAgent.

@export var agent: NucleusTargetingAgent
@export var sensor_enabled: bool = true:
	set(value):
		if sensor_enabled == value:
			return

		sensor_enabled = value

		if not is_node_ready():
			return

		if sensor_enabled:
			call_deferred("_seed_overlaps")
		elif _tracker:
			_tracker.clear()

@export var detect_bodies: bool = true
@export var detect_areas: bool = true

var _tracker: NucleusTargetSensorTracker


func _ready() -> void:
	if agent == null:
		agent = NucleusTargetResolver.find_agent(self)

	if agent == null:
		NucleusLog.error(
			"%s requires a NucleusTargetingAgent." % get_path(),
			&"TargetAreaSensor2D",
		)
		return

	_tracker = NucleusTargetSensorTracker.new(
		agent,
		self,
	)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	call_deferred("_seed_overlaps")


func _exit_tree() -> void:
	if _tracker:
		_tracker.clear()


func _seed_overlaps() -> void:
	if not sensor_enabled or _tracker == null or not monitoring:
		return

	if detect_bodies:
		for body: Node in get_overlapping_bodies():
			_register(body)

	if detect_areas:
		for area: Area2D in get_overlapping_areas():
			_register(area)


func _register(source: Node) -> void:
	if not sensor_enabled or _tracker == null:
		return

	_tracker.register_source(source)


func _unregister(source: Node) -> void:
	if _tracker == null:
		return

	_tracker.unregister_source(source)


func _on_body_entered(body: Node2D) -> void:
	if detect_bodies:
		_register(body)


func _on_body_exited(body: Node2D) -> void:
	if detect_bodies:
		_unregister(body)


func _on_area_entered(area: Area2D) -> void:
	if detect_areas:
		_register(area)


func _on_area_exited(area: Area2D) -> void:
	if detect_areas:
		_unregister(area)
