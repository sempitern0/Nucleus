# Iteration 20 — World Presentation Utilities

## Objective

Recover two proven Barebone-era capabilities that remain broadly useful under
the current Nucleus architecture:

```text
surface-adaptive runtime decals
viewport screenshot capture
```

This is a narrow reuse iteration, not a reopening of broad baseline expansion.

## Audited base

Prepared against:

```text
sempitern0/Nucleus
main
8b0f4baac882563a603b53ffd98361ef4eb3c8ef
```

That base already includes Iteration 19 productization.

## SmartDecal reuse decision

Barebone's SmartDecal already demonstrated useful behavior:

```text
native Decal
surface-normal alignment
random size
random roll
delayed fade
```

Nucleus keeps the idea but redesigns the contract.

### Improvements

```text
Nucleus-prefixed 3D-specific public class
robust orientation for floor / ceiling / walls / arbitrary normals
optional tangent hint
planar-only size randomization
native projection depth left under Decal.size.y
editor configuration warnings
emission-aware fading
optional NucleusPoolable release
visual reset/recapture lifecycle
headless basis tests
curved-surface validation scene
```

There is no DecalManager Autoload.

## Screenshot reuse decision

Barebone captured the Viewport through a global WindowManager.

Nucleus keeps only the stateless reusable operation:

```text
Viewport
→ await frame_post_draw
→ Image
→ PNG/JPEG/WebP
```

The API lives in `NucleusWindow`.

Writable screenshot location lives in `NucleusPaths`.

Directory creation reuses `NucleusFileUtils`.

There is no screenshot Autoload and no global `screenshot_taken` signal.

## Versioning

These are additive public APIs, so the development version advances:

```text
0.1.0-dev.1
→
0.2.0-dev.1
```

No tagged release is invented by this iteration.

## Validation

Automated coverage adds:

```text
SmartDecal surface-basis/cardinal/curved-normal tests
SmartDecal invalid-normal/config-warning tests
screenshot path sanitization/extension tests
real PNG file-save test under user-data
null viewport capture safety
```

Editor visual validation adds:

```text
examples/validation/smart_decal_3d.tscn
```

The fixture checks projection against flat and curved geometry.

## Boundary

Still intentionally excluded:

```text
physics hit detection
surface/material impact classification
global decal manager
global decal budget
video recording
trailer encoding
automatic HUD discovery/hiding
Steam-specific upload tooling
```

Those are either game-specific, project-policy, or dedicated tooling concerns.

## Next step

After CI and visual decal validation pass, use this Nucleus snapshot to begin the
planned real game.

Further baseline changes should be driven by production evidence from that game.
