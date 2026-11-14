# Technical Design

Status: M1 scope, SVTLW-22. Covers architecture decisions that apply now. Sections marked *later* are planned, not built.

## Engine and language

- Godot 4.7 (pinned in `game/project.godot`), GDScript with static typing on all functions and member variables.
- Renderer: GL Compatibility, for Windows-first compatibility.
- Stretch mode `canvas_items` with aspect `keep`, base resolution 1280×720.

## Folder layout

```
game/
  autoload/    global services only
  scenes/      .tscn files, grouped by screen or entity
  scripts/     gameplay logic, one class per file
  resources/   .tres data definitions and their script classes
  ui/          UI scenes and theme resources
  systems/     wave, combat, economy, research, narrative, save
  shaders/
tests/         mirrors game/ layout
assets/        art, audio, CREDITS.md
tools/         balance simulator and build helpers (later)
```

## Naming

- Files and functions: `snake_case`.
- `class_name`: `PascalCase`, one per file.
- Constants: `SCREAMING_SNAKE_CASE`.

## Architecture rules

- Systems talk through signals. No system reaches into another system's internals.
- Autoloads are limited to `GameState`, `SaveManager` and `AudioManager`. Other systems are scenes or plain scripts owned by a scene.
- All content definitions (units, enemies, upgrades, waves, dialogue) are `Resource` subclasses saved as `.tres`. Balance values never sit in gameplay scripts.
- Gameplay advances on a fixed-step simulation tick. Pause, speed changes and offline calculation all run through that tick, so outcomes are repeatable for a given seed.
- Projectiles and impact effects are pooled. Nodes are not created and freed per shot.
- Per-enemy logic is updated by a manager in batches, not in each enemy's `_physics_process`.

## Combat pipeline (M1)

One function computes damage: base damage, times upgrade multiplier, then critical roll, minus armour (with a floor of zero), then resistance. M1 uses the physical type only. Elemental types arrive with the Arcane branch in M3.

## Save system (M1)

- JSON with a top-level `schema_version`.
- Write to `<slot>.tmp`, then rename over `<slot>.json`, so a crash never leaves a half-written save.
- On load, validate the structure. If the file is corrupt, keep the last valid save and report it. Never overwrite a valid save with corrupt data.
- Autosave runs at wave end and on quit, never mid-tick.
- Migrations: each schema version has a step function. Full migration tests arrive with SVTLW-93 in M8.

## Large numbers (later)

Values that can grow past double precision use a mantissa and exponent representation. Display uses suffixes and scientific notation. Saves store the exact representation. This is planned for M4 (SVTLW-70 to SVTLW-72). M1 uses plain integers and floats, with values kept far below overflow.

## Testing

- Framework: GUT or gdUnit4. Chosen in SVTLW-46 (M1).
- Tests live in `tests/` and mirror `game/`.
- Validation: the project opens headless without errors and the test suite passes before any merge.

## Performance targets (later)

Benchmark scenes at 100, 250, 500 and 1000 active enemies. Results and the minimum hardware target go in `docs/PERFORMANCE.md` (M7). Frame budget and hardware target are decided after the first benchmark, not guessed now.

## Offline progression (later)

The game stores a timestamp on close. On launch it applies passive production for the elapsed time, up to a configurable cap. Battles are not simulated offline.

## Save slots (deferred)

M1 to M7 use one save slot. The file is `user://save_slot_1.json` (with `.tmp` and `.bak` beside it), and `SaveManager` reads and writes only that path. The file name for slot 1 must not change, so existing saves keep loading.

Multiple slots are deferred. They need a slot id in every path, a slot picker in the menus and a rule for which slot autosave writes to. That is not a small change, so SVTLW-93 adds no `slot` helper. When slots arrive, slot 1 keeps the current file name, and `game/tests/test_migrations.gd` must still pass.

Schema migrations: only schema version 1 exists. `SaveManager.load_game` rejects any other version and keeps the current state. The v1 fixture in `game/tests/fixtures/` is the oldest save covered, because no older schema was ever shipped.
