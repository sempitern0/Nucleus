# Nucleus UI Components

Target engine: Godot 4.7.x.


## Production tooling

The second UI iteration adds production primitives rather than visual widgets:

```text
modal stack / dialogs
bounded toast queue
translated native tooltips
hold-to-confirm
page/tab coordination
animated numeric values
safe-area adaptation
responsive breakpoints
fixed-row list virtualization
```

These tools remain scene-owned. A project can build a persistent UI shell from
them without introducing another global manager.

See `docs/guides/ui_production_quickstart.md` for editor-first setup.
