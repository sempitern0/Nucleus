# Nucleus Utility Layer

Target engine: Godot 4.7.x.

## Purpose

Utilities are small, stateless or value-oriented building blocks that are
plausibly useful across unrelated games.

They are not an excuse to rebuild Godot's standard library.

A helper belongs here only when it:

1. Solves a recurring cross-project problem.
2. Has no gameplay-domain knowledge.
3. Does not require application-lifetime state.
4. Adds meaningful behavior over the native Godot API.
5. Has a narrow name and responsibility.

No utility in this directory is an Autoload.

## Current utility surface

```text
core/utils/
├── collections/
│   ├── array_utils.gd
│   ├── dictionary_utils.gd
│   └── shuffle_bag.gd
├── enums/
│   └── enum_utils.gd
├── files/
│   └── file_utils.gd
├── geometry/
│   └── random_geometry.gd
├── identity/
│   └── uuid.gd
├── nodes/
│   └── node_utils.gd
├── time/
│   └── time_utils.gd
└── version/
    └── semantic_version.gd
```

## UUID

```gdscript
var id: String = NucleusUuid.v4()
```

Unlike the OmniKit implementation, UUIDv4 generation uses
`Crypto.generate_random_bytes(16)` rather than the gameplay PRNG.

The version and RFC variant bits are then applied explicitly.

Use the gameplay PRNG for gameplay randomness. Use UUID for persistent identity.

## Semantic versions

```gdscript
var version := NucleusSemanticVersion.parse(
    "1.4.0-rc.2+steam"
)

var required := NucleusSemanticVersion.parse("1.3.0")

if version.is_greater_than(required):
    ...
```

The implementation follows SemVer precedence, including prerelease identifier
rules. Build metadata does not affect precedence.

This is useful for:

- save-schema/tool compatibility;
- network protocol compatibility;
- optional module/plugin compatibility;
- update metadata.

## Shuffle bag

```gdscript
var bag := NucleusShuffleBag.new(
    ["a", "b", "c"]
)

var next_value: Variant = bag.draw()
```

A supplied `RandomNumberGenerator` enables deterministic behavior.

By default, refill tries to avoid repeating the final item of the previous bag
as the first item of the next bag.

## Arrays and Dictionaries

These classes intentionally contain only operations that are meaningfully
missing from the built-in types.

Examples:

```gdscript
NucleusArrayUtils.flatten(...)
NucleusArrayUtils.chunk(...)
NucleusArrayUtils.unique(...)
NucleusArrayUtils.intersection(...)

NucleusDictionaryUtils.deep_merge(...)
NucleusDictionaryUtils.deep_get(...)
NucleusDictionaryUtils.deep_set(...)
```

Native methods such as `Array.shuffle()`, `Array.pick_random()`, `Array.reduce()`
or String case-conversion methods are not wrapped.

## Enum helpers

GDScript enums are Dictionaries whose numeric values do not have to match the
index of their key.

`NucleusEnumUtils.name_for_value()` searches by the actual numeric value. This
fixes the old OmniKit assumption that enum value and key-array index were the
same thing.

## Filesystem helpers

`NucleusFileUtils` handles host/user filesystem trees:

```gdscript
NucleusFileUtils.ensure_directory(...)
NucleusFileUtils.list_files_recursive(...)
NucleusFileUtils.copy_directory_recursive(...)
NucleusFileUtils.remove_directory_recursive(...)
```

It is not intended for runtime discovery of packaged `res://` resources in
exports. Use `ResourceLoader` for project resources.

Save slot deletion now delegates to this utility rather than carrying its own
private recursive-delete implementation.

## Random geometry

The random geometry helper contains sampling operations rather than becoming
another giant geometry library.

```gdscript
NucleusRandomGeometry.point_in_circle(...)
NucleusRandomGeometry.point_on_circle(...)
NucleusRandomGeometry.point_in_annulus(...)
NucleusRandomGeometry.point_in_rect(...)
NucleusRandomGeometry.direction_2d(...)
NucleusRandomGeometry.direction_3d(...)
```

Sampling is uniform by area/surface.

This fixes several OmniKit issues:

- `random_inside_unit_circle()` actually sampled the circumference;
- `random_on_unit_circle()` actually sampled the interior with radial bias;
- random Rect2 points ignored `rect.position`;
- normalized random cube vectors are not uniform sphere samples.

## Node utilities

Only generic traversal remains:

```gdscript
NucleusNodeUtils.descendants(...)
NucleusNodeUtils.ancestors(...)
NucleusNodeUtils.tree_depth(...)
NucleusNodeUtils.set_owner_recursive(...)
```

Type searches were not copied because `Node.find_child()` and
`Node.find_children()` already provide native search facilities.

UI visibility helpers, node positioning and removal behavior belong to the
future Components/UI layer rather than this generic utility layer.
