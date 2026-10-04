# Foundation Quickstart

## 1. Open the template

Use Godot 4.7.x and import the repository root containing `project.godot`.

The baseline does not force a game main scene. Create your project's own main
scene when starting a game.

## 2. Understand the default Autoloads

The template already configures:

```text
NucleusApp
NucleusSettings
NucleusInput
NucleusAudio
NucleusSave
NucleusSceneFlow
```

Do not duplicate these services inside each scene.

EventBus and NetworkHandler are optional and are intentionally absent from the
default Autoload list.

## 3. Build gameplay by composition

Add only the components a scene needs.

For example:

```text
Player
├── Health (NucleusValuePool)
│   └── Regenerator (optional)
├── DamageReceiver
├── StateMachine
├── ActionSet
└── TargetingAgent
```

Exact node placement depends on the feature contracts and your game.

## 4. Prefer native Godot nodes

Keep using native:

```text
CharacterBody2D/3D
Camera2D/3D
Area2D/3D
AnimationTree
Control
InputMap
TranslationServer
```

Nucleus components adapt and compose these APIs.

## 5. Check the Scene dock warnings

Some editor-facing components emit native Godot configuration warnings in
Iteration 18. Resolve red/yellow scene configuration indicators before relying
on runtime auto-discovery.

## 6. Validate the baseline

Run the commands in `validation_ci_quickstart.md` before making Nucleus changes
part of another project template.
