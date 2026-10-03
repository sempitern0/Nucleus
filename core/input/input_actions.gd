class_name NucleusInputActions
extends RefCounted
## Semantic input actions included by the Nucleus template.
##
## Games are free to add or remove actions. Core systems never require these
## actions to exist; they are provided as useful, device-agnostic defaults.

const MOVE_LEFT: StringName = &"move_left"
const MOVE_RIGHT: StringName = &"move_right"
const MOVE_FORWARD: StringName = &"move_forward"
const MOVE_BACK: StringName = &"move_back"

const LOOK_LEFT: StringName = &"look_left"
const LOOK_RIGHT: StringName = &"look_right"
const LOOK_UP: StringName = &"look_up"
const LOOK_DOWN: StringName = &"look_down"

const PRIMARY_ACTION: StringName = &"primary_action"
const SECONDARY_ACTION: StringName = &"secondary_action"
const INTERACT: StringName = &"interact"
const PAUSE: StringName = &"pause"
