# Movement, Control, and Camera Contract

## Scope

```text
components/gameplay/control
components/gameplay/movement
components/gameplay/camera
```

Game-facing movement and camera behavior is scene-owned and split into small
adapters around Godot-native character/camera nodes.

## Input versus movement

Control components translate semantic Nucleus/Godot input into motion intent.
Movement components apply that intent to the appropriate `CharacterBody2D` or
`CharacterBody3D`.

Keep input collection separate from physical motion so AI, replay, local
multiplayer, or game-specific controllers can provide motion intent without
rewriting movement.

## Godot-native motion

`CharacterBody2D`, `CharacterBody3D`, their `velocity`, and `move_and_slide()`
remain the physical source of truth.

Nucleus should not maintain a second transform/velocity model.

## Cameras

Camera helpers compose follow/look/FOV behavior around `Camera2D`/`Camera3D` and
scene pivots.

Game-feel feedback is a presentation layer on top of the camera, not part of
movement physics. Iteration 17 introduced stackable source-owned feedback,
impulses, recoil/kick/shake, head bob, landing feedback, and temporary FOV
offsets.

See `camera_game_feel.md` for the feedback contract.

## Animation integration

Velocity adapters project `CharacterBody` motion into AnimationTree parameters.
The movement component does not select animation clips directly.

See `animation_integration.md`.

## Multiplayer

Local-player ownership belongs to the input layer. A movement component should
receive intent for its player; it should not inspect global "last used device"
state as an ownership mechanism.

## Extension rule

Add a new movement model only when its physics policy differs materially. Add a
controller/intent producer when only the source of movement input changes.
