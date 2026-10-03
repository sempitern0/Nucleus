class_name NucleusUIMotionProfile
extends Resource
## Reusable timing policy for UI tweens.

@export_range(0.0, 10.0, 0.01, "or_greater")
var duration: float = 0.18

@export var transition: Tween.TransitionType = Tween.TRANS_QUART
@export var easing: Tween.EaseType = Tween.EASE_OUT

@export var ignore_time_scale: bool = true
@export var respect_reduced_motion: bool = true
