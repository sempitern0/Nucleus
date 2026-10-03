class_name NucleusAudioCue
extends Resource
## Reusable non-positional audio playback descriptor.
##
## Use AudioStreamRandomizer as [member stream] when a cue needs weighted random
## samples or built-in random pitch/volume variation.

@export var stream: AudioStream
@export var bus: StringName = NucleusAudioBuses.SFX
@export_range(0.0, 4.0, 0.01, "or_greater")
var volume_linear: float = 1.0
@export_range(0.01, 4.0, 0.01, "or_greater")
var pitch_scale: float = 1.0
@export_range(0.0, 3600.0, 0.01, "or_greater")
var from_position: float = 0.0
