# Wizard of Words

Wizard of Words is an in-development word-crafting duel built with Godot. Players cast words across a living board where magical bonuses can remain hidden until nearby runes reveal them.

## Current features

- Complete 15x15 word-game rules, cross-word validation, premium scoring, blanks, trading, passing, bingo bonuses, and end-game penalties
- Local hotseat play and three AI difficulty levels
- Data-driven rulesets and selectable dictionary combinations
- Fog-of-war boards with bonuses revealed through play
- Themed bonus-word grimoires and multiple visual skins
- Mouse placement plus drag-and-drop rack and board interactions
- Headless smoke, UI, blank-tile, and trade tests
- Scene-based title, setup, board, HUD, blank-picker, and trade-dialog UI

## Signature mode

**Spiral Sigil** replaces the familiar static board with a rotationally symmetric spiral of bonuses hidden beneath fog. The long-term direction expands this into seeded, shareable living boards with reveal effects, bonus decay, and additional bloom behavior.

## Requirements

- Godot 4.7.1 or a compatible Godot 4 release

Open `project.godot` in Godot and run the main scene.

## Tests

Tests are headless `SceneTree` scripts under `tests/`. Run them from the project directory with your Godot executable:

```text
godot --headless --path . --script tests/smoke_test.gd
godot --headless --path . --script tests/asset_test.gd
godot --headless --path . --script tests/board_shell_test.gd
godot --headless --path . --script tests/blank_test.gd
godot --headless --path . --script tests/trade_test.gd
godot --headless --path . --script tests/ui_test.gd
godot --headless --path . --script tests/ui_components_test.gd
```

## Project guide

- [`DESIGN.md`](DESIGN.md) contains the game vision, implemented milestones, and feature backlog.
- [`ARCHITECTURE.md`](ARCHITECTURE.md) defines the staged modularization and authoritative online-play roadmap.
- [`LICENSES.md`](LICENSES.md) records asset and dictionary provenance and release-review requirements.

Core rules and data live under `scripts/` and `data/`. Focused scenes under `scenes/screens/` and `scenes/components/` now own the interface; `scripts/main.gd` remains the temporary match coordinator while authoritative state and commands are extracted.

## Status

This is a playable development prototype. Assets and dictionary licenses must be reviewed against `LICENSES.md` before a public or commercial release.
