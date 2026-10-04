# UI Production Tooling — Godot Editor Quickstart

This guide is the practical companion to the technical API reference.

The objective is that a developer can integrate each component from the Godot
editor without first understanding every internal class.

---

## 1. Modal dialog in a menu

### Editor setup

1. Open the scene that owns your persistent menu/HUD UI.
2. Drag `components/ui/modal/ui_modal_host.tscn` into the scene.
3. Select `UIModalHost/Root/ModalContent`.
4. Add your dialog panel as a child of `ModalContent`.
5. Keep the dialog panel centered using normal Godot anchors/Containers.
6. Add a regular `Node` below the dialog panel.
7. Attach `components/ui/modal/ui_modal.gd`.
8. Add `NucleusUIPresenter` and `NucleusUIFocusScope` as children of the dialog
   panel if you want animation and automatic controller/keyboard focus.
9. Drag those nodes into the `presenter` and `focus_scope` Inspector fields.

Recommended tree:

```text
PersistentUI
└── UIModalHost
    └── Root
        ├── Backdrop
        └── ModalContent
            └── DeleteSaveDialog
                ├── UIModal
                ├── UIPresenter
                ├── UIFocusScope
                └── PanelContainer
                    └── ...
```

### Open from code

```gdscript
@onready var modal_host: NucleusUIModalHost = %UIModalHost
@onready var delete_modal: NucleusUIModal = %DeleteSaveModal


func _on_delete_pressed() -> void:
    modal_host.open(delete_modal)
```

`ui_cancel` and optional backdrop clicks are handled by the host.

### Add confirm/cancel wiring

Add another Node with `ui_dialog.gd` and drag:

```text
Title Label
Message Label
Confirm Button
Cancel Button
Modal component
```

into its Inspector fields.

Connect your destructive action to:

```gdscript
dialog.confirmed.connect(_delete_save)
```

The dialog closes itself through the modal request; the gameplay action remains
in your own code.

---

## 2. Toast notifications

### Editor setup

1. Instance `components/ui/toast/ui_toast_host.tscn` under your persistent UI.
2. Select `UIToastHost`.
3. Choose placement, maximum simultaneous toasts, width, and margins.
4. Style the following Theme type variations if desired:

```text
NucleusToast
NucleusToastTitle
NucleusToastMessage
```

No extra scene is required for the default implementation.

### Show a toast

```gdscript
%UIToastHost.enqueue(
    tr("SAVE_COMPLETE"),
    tr("SAVED"),
    2.5,
    &"save_complete",
)
```

A repeated non-empty dedupe key is rejected while the previous notification is
still queued or visible.

Use priority for urgent UI messages:

```gdscript
toast_host.enqueue(
    "Controller disconnected",
    "Input",
    5.0,
    &"controller_disconnect",
    100,
)
```

---

## 3. Translated tooltip in the editor

Godot already has a native tooltip system.

1. Select the Control that needs help text.
2. Add a child Node.
3. Attach `components/ui/tooltip/ui_tooltip_binding.gd`.
4. Set `text_key` to the translation key.
5. Optionally set fallback text.

The component updates `Control.tooltip_text` when language changes.

To change the global hover delay use:

```text
Project > Project Settings
→ GUI
→ Timers
→ Tooltip Delay Sec
```

Style native tooltips in your Theme with:

```text
TooltipPanel
TooltipLabel
```

Buttons can also append Shortcut information through Godot's
`shortcut_in_tooltip` property.

---

## 4. Hold-to-confirm button

Typical use: delete save, overwrite profile, irreversible purchase, quit during
unsaved work.

### Editor tree

```text
DeleteButton
├── HoldToConfirm
└── ProgressBar
```

1. Add `ui_hold_to_confirm.gd` below the Button.
2. Drag the Button into `target`.
3. Drag the ProgressBar into `progress_target`.
4. Set hold duration, for example `0.8`.
5. Connect `HoldToConfirm.confirmed` to the destructive action.

Important:

```text
Do not connect Button.pressed to the destructive action.
```

The normal Button signal still exists because this is composition, not a custom
Button subclass.

This works with mouse, touch, keyboard, and controller as long as the BaseButton
receives normal Godot press/release interaction.

---

## 5. Settings pages / tabs

Build pages with ordinary Controls:

```text
Settings
├── Navigation
│   ├── GraphicsButton
│   ├── AudioButton
│   └── InputButton
├── Pages
│   ├── Graphics
│   ├── Audio
│   └── Input
└── UIPageController
```

On `UIPageController`:

1. Set `pages` to Graphics, Audio, Input.
2. Set `tab_buttons` in the same order.
3. Choose `initial_index`.
4. Enable/disable animated transitions.

If tab buttons use `toggle_mode`, the controller keeps their selected state in
sync without emitting extra toggle signals.

Open a page from code:

```gdscript
page_controller.show_page_by_name(&"Audio")
```

Place a `NucleusUIFocusScope` inside each page if you want controller/keyboard
focus to be restored automatically when switching.

---

## 6. Animated score, health, XP, or progress

### Editor setup

Add a Node with `ui_animated_value.gd`.

Assign any combination of:

```text
Range target  → ProgressBar, TextureProgressBar, Slider...
Label target  → numeric text
```

Example:

```gdscript
health_display.set_value(player.health)

score_display.set_value(score)
```

Inspector formatting fields let you configure:

```text
decimals
prefix
suffix
"{value}" text template
```

---

## 7. Safe-area container

Use this around interactive HUD/menu content on mobile/fullscreen platforms.

Recommended tree:

```text
CanvasLayer
└── SafeArea
    ├── UISafeArea
    └── MarginContainer / UI content
```

1. Make `SafeArea` a full-rect Control.
2. Add `ui_safe_area.gd` as a child.
3. Leave `force_full_rect_anchors` enabled.
4. Add `extra_margins` for design padding if desired.

Native display safe-area data is used where Godot exposes it. In Godot 4.7
that means Android/iOS; fullscreen desktop builds use the display's usable
rectangle fallback.

`fallback_margins` is especially useful for a custom Web host shell, where the
browser may have layout constraints that are not represented by Godot's native
safe-area API.

Do not put decorative full-screen backgrounds inside the safe area. Only
interactive/important content needs notch/status-bar protection.

---

## 8. Responsive breakpoints

Containers and anchors should solve most responsive layout.

Use breakpoints only when the UI genuinely changes structure.

Add:

```text
ResponsiveRoot
├── UIBreakpoints
├── DesktopSidebar
│   └── UIResponsiveVisibility
└── CompactBottomBar
    └── UIResponsiveVisibility
```

Configure the visibility components:

```text
DesktopSidebar
  compact: false
  regular: true
  wide: true

CompactBottomBar
  compact: true
  regular: false
  wide: false
```

The default thresholds are logical viewport widths, so window resizing and
Godot stretch settings are handled consistently.

---

## 9. Virtual list for thousands of rows

Use this only when ordinary Containers become expensive. The initial
virtualizer is best suited to display-oriented rows such as leaderboards,
logs, server browsers, or history feeds.

### Editor tree

```text
ScrollContainer
├── Content
└── UIVirtualList
```

`Content` must be a plain `Control`, not a VBoxContainer.

Create a reusable item scene whose root is a `Control`.

In `UIVirtualList`:

1. Drag the ScrollContainer into `scroll_container`.
2. Drag `Content` into `content`.
3. Assign your row PackedScene to `item_scene`.
4. Set the exact row height and spacing.
5. Set the data:

```gdscript
virtual_list.set_items(leaderboard_entries)
```

Bind recycled rows:

```gdscript
func _ready() -> void:
    virtual_list.bind_item.connect(_bind_leaderboard_row)


func _bind_leaderboard_row(
    item: Control,
    index: int,
    data: Variant,
) -> void:
    item.get_node("Name").text = data.player_name
    item.get_node("Score").text = str(data.score)
```

Do not store the data index permanently inside gameplay logic: the same Control
will later represent another row.

Use a normal VBoxContainer for small lists. Virtualization is an optimization,
not the default UI architecture.

For large controller/keyboard-selectable datasets, prefer `ItemList`, `Tree`,
or add an explicit indexed focus adapter. This first virtual list virtualizes
rows and binding, not focus navigation.

---

## Suggested persistent UI shell

A production project often ends up with something similar to:

```text
PersistentUI
├── SafeArea
├── HUD
├── Menus
├── UIModalHost
├── UIToastHost
└── UIScreenEffects
```

Nucleus does not require this exact tree. It is a practical composition that
keeps transient screens scene-owned while giving application-level UI a stable
lifetime.


## Split-screen note

`UIModalHost` and `UIToastHost` use CanvasLayer. In a split-screen game, create
a host for each Viewport that needs independent UI, or assign the CanvasLayer's
`custom_viewport`. A single CanvasLayer is not automatically shared across all
SubViewports.
