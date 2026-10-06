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
Movement components apply that intent to `CharacterBody2D` or
`CharacterBody3D`.

Keep input collection separate from physical motion so AI, replay, local
multiplayer, or game-specific controllers can provide intent without rewriting
movement.

## Godot-native motion

`CharacterBody2D`, `CharacterBody3D`, their `velocity`, and `move_and_slide()`
remain the physical source of truth. Nucleus does not maintain a second motion
model.

## Cameras

Camera helpers compose follow/look/FOV behavior around native camera nodes and
scene pivots.

Game-feel feedback is a presentation layer on top of the camera, not part of
movement physics. Stackable source-owned feedback supports impulses,
recoil/kick/shake, head bob, landing feedback, and temporary FOV offsets.

See `camera_game_feel.md` for the feedback contract.

## Animation integration

Velocity adapters project `CharacterBody` motion into `AnimationTree`
parameters. Movement components do not select clips directly.

A production 3D model remains a presentation child of the stable
`CharacterBody3D` gameplay root. See `animation_integration.md` and the 3D
character animation tutorial.

## Multiplayer

Local-player ownership belongs to the input layer. A movement component receives
intent for its player; it should not inspect global last-used-device state as an
ownership mechanism.

## Extension rule

Add a movement model only when its physics policy differs materially. Add a
controller/intent producer when only the source of movement input changes.
