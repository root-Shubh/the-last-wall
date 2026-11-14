# Decisions

Each design or technical decision is recorded here: date, decision, reason, and alternatives rejected. Newest entries go at the bottom of their section.

## Process

### 2026-11-14: Branching strategy
- **Decision:** `master` is the golden source and receives releases only. `develop` is the integration branch. `qa`, `staging` and `release` are protected environment branches. Feature work uses `feature-SVTLW-<n>` from `develop`, merged by pull request.
- **Reason:** the team process agreed for sv_devtools, applied here so both projects follow the same rules.
- **Rejected:** `main` as default (kept `master` to match the team process); trunk-based development with no `develop` (promotion through environments needs a stable integration point).

### 2026-11-14: Commit and Jira convention
- **Decision:** commit subject `SVTLW-<n> #comment <summary>`, with the same summary posted as a Jira comment.
- **Reason:** Jira progress mirrors commits exactly.

### 2026-11-14: Repository visibility
- **Decision:** the repository is public. The licence text is owned and changed by the repository owner.
- **Reason:** branch protection rulesets require a paid plan on private repositories. The owner chose to make the repo public to enable them.
- **Rejected:** upgrading to a paid plan (not approved).

### 2026-11-14: Pull requests and merges
- **Decision:** every change goes through a pull request into `develop`. `master` changes only through release promotion. The owner may merge through the admin bypass in the ruleset.
- **Reason:** review trail for each ticket and protection against accidental force pushes.

## Engine and tooling

### 2026-11-14: Godot 4.7 with GDScript
- **Decision:** Godot 4.7.2 stable, GDScript, static typing everywhere.
- **Reason:** the brief specifies Godot 4.x and GDScript. Static typing catches errors at parse time and helps the performance target.
- **Rejected:** C# (not required, slower iteration in the editor for this scope).

### 2026-11-14: GL Compatibility renderer
- **Decision:** `gl_compatibility` for both desktop and mobile settings.
- **Reason:** Windows-first target with broad hardware support. The 2D game does not need the Forward+ features.
- **Rejected:** Forward+ (heavier, not needed for 2D).

### 2026-11-14: Base resolution 1280×720
- **Decision:** window 1280×720, stretch mode `canvas_items`, aspect `keep`.
- **Reason:** a readable battlefield with hundreds of enemies needs a fixed logical size.

## Design

### 2026-11-14: Character choice is cosmetic
- **Decision:** male and female avatars have identical gameplay.
- **Reason:** brief requirement, and it keeps balance work independent of the choice.

### 2026-11-14: Only physical damage in M1
- **Decision:** the combat pipeline supports damage types, but M1 uses physical only.
- **Reason:** elemental damage depends on the Arcane research branch, which is M3.

### 2026-11-14: Upgrades are data, not code
- **Decision:** upgrade definitions are Resources with base cost, cost multiplier, effect, maximum level and prerequisites.
- **Reason:** the balance simulator (M7) needs to read them without running game code.

## Technical

### 2026-11-14: Save writes are atomic
- **Decision:** write to a temporary file, then rename. Corrupt saves never overwrite a valid save.
- **Reason:** the brief forbids silent overwrite of valid saves.

### 2026-11-14: Fixed-step simulation tick
- **Decision:** combat and waves advance on a fixed tick, so pause and speed changes do not alter outcomes for a given seed.
- **Reason:** deterministic tests, and offline logic that does not depend on frame rate.

### 2026-11-14: Large numbers deferred to M4
- **Decision:** M1 uses plain numeric types. Mantissa and exponent representation comes with the instability work in M4.
- **Reason:** M1 values stay far below overflow, and the representation is only needed once progression reaches it.
